require 'mail'
require_relative 'google_client'
settings = YAML.load(File.read("secrets.yml"))

Mail.defaults do
  delivery_method :smtp, address: settings['smtp']['host'], port: settings['smtp']['port']
end


email = Mail.read("./emails/start_email.eml")


cli = GoogleClient.new(settings["spreadsheet"]["id"])

cli.read_and_set_sended_every_row do |row|

  if row.spedite == "SI"
    false
  else

    #qua faremo api richiesta a chi inviare
    email.to row.email
    email.deliver!

    true
  end

end



