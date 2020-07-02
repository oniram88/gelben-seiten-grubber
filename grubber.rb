require 'httparty'
require 'nokogiri'


class Contact < OpenStruct
  def to_csv
    [azienda, indirizzo, cap, citta, telefono, fax, email, web]
  end
end

class PageDownloader

  # @param [String] who
  def initialize(who:)
    @who = who
  end

  # @return [Array<Contact>]
  def contacts
    results = []
    addresses.each do |indirizzo|
      out = get_contact(indirizzo)
      unless out.nil?
        results << Contact.new(out)
      end
    end
    results
  end


  # @return [Array<String>]
  def addresses
    response = HTTParty.post('https://www.gelbeseiten.de/Suche', body: {"WAS": "Kunststofferzeugnisse", "WO": @who, "distance": 50000})
    # puts response.inspect
    doc = Nokogiri::HTML(response)
    indirizzi = []
    doc.css("article>a").each do |add|
      indirizzi << add[:href]
    end
    indirizzi
  end


  ##
  # Estrapola da un indirizzo le informazioni di contatto presenti
  def get_contact(indirizzo)
    begin
      out = {}

      single_contact = Nokogiri::HTML(HTTParty.get(indirizzo))
      contatti = single_contact.at_css('#kontaktdaten')

      out[:azienda] = contatti.at_css('address>strong').content rescue ""
      out[:indirizzo_full] = contatti.css('address>p').collect(&:content).join(" ") rescue ""
      out[:indirizzo] = contatti.css('address>p').first.content rescue ""
      cap_citta = contatti.css('address>p').last.content.strip.match(/^(?<cap>[0-9]+)(?<citta>.*)$/) rescue ""
      out[:cap] = cap_citta[:cap] rescue ""
      out[:citta] = cap_citta[:citta] rescue ""

      out[:telefono] = contatti.at_css("span[data-role='telefonnummer']")["data-suffix"] rescue ""
      out[:fax] = contatti.at_css("span[property='faxnumber']").content rescue ""
      out[:email] = contatti.at_css("a[property='email']")["content"] rescue ""
      out[:web] = contatti.at_css("a[property='url']")["href"] rescue ""


      out.each do |k, v|
        out[k] = v.to_s.strip
      end

      puts out.inspect

    rescue Exception => e
      puts "Problemi download #{indirizzo}"
    end
    out
  end


end


# Baden Württemberg ( Freiburg, Karlsruhe, Stuttgart, Tübingen)
# Nordrhein -Westfalen ( Arnsberg, Detmold, Düsseldorf, Köln, Münster)
# Bayern (  te le faccio avere…….
#   Rheinland Pfalz
# Turinga
# Niedersachsen
# Brandenburg
# Hessen
# Berlin
# Saarland
# Sachsen
# Sachsen Anhalt
# Mecklenburg Vorpommern
# Schleswig Holstein
# Hamburg
# Bremen

# d = PageDownloader.new(who: 'Berlin')
d = PageDownloader.new(who: 'Berlin')

puts d.contacts.inspect

CSV.open("./berlino.csv", "wb") do |csv|

  d.contacts.each do |c|
    csv << c.to_csv
  end

end