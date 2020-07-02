require 'httparty'
require 'nokogiri'


class Contact < OpenStruct
  def to_csv
    [chiave_ricerca, pagine_gialle, azienda, indirizzo, cap, citta, telefono, fax, email, web]
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
    indirizzi = []
    while response
      # puts response.inspect
      doc = Nokogiri::HTML(response)
      doc.css("article>a").each do |add|
        indirizzi << add[:href]
      end
      response = false

      #cerchiamo se è presente la prossima pagina
      if doc.at_css(".mod-paginierung a[title='Weiter']")
        response = HTTParty.get(doc.at_css(".mod-paginierung a[title='Weiter']")['href'])
      end

    end
    indirizzi.uniq
  end


  ##
  # Estrapola da un indirizzo le informazioni di contatto presenti
  def get_contact(indirizzo)
    begin
      out = {}
      puts indirizzo
      single_contact = Nokogiri::HTML(HTTParty.get(indirizzo))
      contatti = single_contact.at_css('#kontaktdaten')

      out[:chiave_ricerca] = @who
      out[:pagine_gialle] = indirizzo
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


results = []
[
  "Freiburg",
  "Karlsruhe",
  "Stuttgart",
  "Tübingen",
  "Arnsberg",
  "Detmold",
  "Düsseldorf",
  "Köln",
  "Münster",
  "Bayern",
  "Rheinland Pfalz",
  "Turinga",
  "Niedersachsen",
  "Brandenburg",
  "Hessen",
  "Berlin",
  "Saarland",
  "Sachsen",
  "Sachsen Anhalt",
  "Mecklenburg Vorpommern",
  "Schleswig Holstein",
  "Hamburg",
  "Bremen"
].each do |who|
  d = PageDownloader.new(who: who)
  results << d.contacts
end

results = results.flatten.uniq { |s| s.azienda }

FileUtils.rm_rf("./output.csv")
CSV.open("./output.csv", "wb") do |csv|

  results.each do |c|
    csv << c.to_csv
  end

end
