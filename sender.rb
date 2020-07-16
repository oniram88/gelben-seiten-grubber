require 'mail'
require_relative 'google_client'
settings = YAML.load(File.read("secrets.yml"))

Mail.defaults do
  delivery_method :smtp,
                  address: "smtp.gmail.com",
                  port: 587,
                  user_name: settings['smtp']['user_name'],
                  password: settings['smtp']['password'],
                  domain: "apcomposite.it",
                  :authentication => 'plain',
                  :enable_starttls_auto => true

end


email = Mail.read("./emails/start_email.eml")
email.from = "Christiane Taschner <export@apcomposite.it>"

cli = GoogleClient.new(settings["spreadsheet"]["id"], page: 'simulazione')

puts "PAGINA SCELTA: #{cli.page}"
counter = 5
while counter > 0
  puts "#{counter} secondi allo start ..."
  sleep 1
  counter -= 1
end


cli.read_and_set_sended_every_row do |row|

  if row.spedite == "SI"
    puts "Email Già spedita: #{row.email}"
    false
  else
    puts "Start Send: #{row.email}=>"
    #qua faremo api richiesta a chi inviare
    email.to row.email
    email.deliver!

    puts "=>spedita a #{row.email}"
    sleep 1
    true
  end

end



