# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::IdentifySender

  def self.run(_channel, mail)

    user_id = mail[ 'x-zammad-customer-id'.to_sym ]
    user = nil
    if user_id
      user = User.lookup(id: user_id)
      if !user
        Rails.logger.debug "Invalid x-zammad-customer-id header '#{user_id}', no such user."
      else
        Rails.logger.debug "Took customer form x-zammad-customer-id header '#{user_id}'."
        if user
          create_recipients(mail)
          return
        end
      end
    end

    # check if sender exists in database
    if mail[ 'x-zammad-customer-login'.to_sym ]
      user = User.find_by(login: mail[ 'x-zammad-customer-login'.to_sym ])
    end
    if !user
      user = User.find_by(email: mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email])
    end
    if !user
      user = user_create(
        login: mail[ 'x-zammad-customer-login'.to_sym ] || mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
        firstname: mail[ 'x-zammad-customer-firstname'.to_sym ] || mail[:from_display_name],
        lastname: mail[ 'x-zammad-customer-lastname'.to_sym ],
        email: mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
      )
    end

    create_recipients(mail)

    mail[ 'x-zammad-customer-id'.to_sym ] = user.id
  end

  # create to and cc user
  def self.create_recipients(mail)
    ['raw-to', 'raw-cc'].each { |item|
      next if !mail[item.to_sym]
      begin
        next if !mail[item.to_sym].addrs
        items = mail[item.to_sym].addrs
        items.each { |address_data|
          user_create(
            firstname: address_data.display_name,
            lastname: '',
            email: address_data.address,
          )
        }
      rescue => e
        # parse not parseable fields by mail gem like
        #  - Max Kohl | [example.com] <kohl@example.com>
        Rails.logger.error 'ERROR: ' + e.inspect
        Rails.logger.error 'ERROR: try it by my self'
        recipients = mail[item.to_sym].to_s.split(',')
        recipients.each { |recipient|
          address = nil
          display_name = nil
          if recipient =~ /<(.+?)>/
            address = $1
          end
          if recipient =~ /^(.+?)<(.+?)>/
            display_name = ($1).strip
          end
          next if address.empty?
          user_create(
            firstname: display_name,
            lastname: '',
            email: address,
          )
        }
      end

    }
  end

  def self.user_create(data)

    # return existing
    user = User.find_by(login: data[:email].downcase)
    return user if user

    # create new user
    role_ids = Role.signup_role_ids

    # fillup
    %w(firstname lastname).each { |item|
      if data[item.to_sym].nil?
        data[item.to_sym] = ''
      end
    }
    data[:password]      = ''
    data[:active]        = true
    data[:role_ids]      = role_ids
    data[:updated_by_id] = 1
    data[:created_by_id] = 1

    user = User.create(data)
    user.update_attributes(
      updated_by_id: user.id,
      created_by_id: user.id,
    )
    user
  end

end
