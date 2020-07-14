require 'httparty'
require 'nokogiri'


class Contact < OpenStruct
  def to_csv
    [chiave_ricerca, pagine_gialle, azienda, indirizzo, cap, citta, telefono, fax, email, web, email_da_sito]
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

      out[:email_da_sito] = ""


      out.each do |k, v|
        out[k] = v.to_s.strip
      end

      # cerco se non presente mail nel sito internet
      if out[:email] == "" and out[:web] != ""
        web_page = Nokogiri::HTML(HTTParty.get(out[:web]))
        if web_page.at_css("a[href^='mailto']")
          out[:email_da_sito] = web_page.at_css("a[href^='mailto']")["href"].match(/^mailto:(.*)$/)[1]
        end
      end


      # puts out.inspect

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
elenco_iniziale = [
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
  "Bremen",
  'Aachen',
  'Ahrweiler',
  'Aichach-Friedberg',
  'Alb-Donau-Kreis',
  'Altenburger Land',
  'Altenkirchen',
  'Altmarkkreis Salzwedel',
  'Altötting',
  'Alzey-Worms',
  'Amberg-Sulzbach',
  'Ammerland',
  'Anhalt-Bitterfeld',
  'Ansbach',
  'Aschaffenburg',
  'Augsburg',
  'Aurich',
  'Bad Dürkheim',
  'Bad Kissingen',
  'Bad Kreuznach',
  'Bad Tölz-Wolfratshausen',
  'Bamberg',
  'Barnim',
  'Bautzen',
  'Bayreuth',
  'Berchtesgadener Land',
  'Bergstraße',
  'Bernkastel-Wittlich',
  'Biberach',
  'Birkenfeld',
  'Böblingen',
  'Bodenseekreis',
  'Börde',
  'Borken',
  'Breisgau-Hochschwarzwald',
  'Burgenlandkreis',
  'Calw',
  'Celle',
  'Cham',
  'Cloppenburg',
  'Coburg',
  'Cochem-Zell',
  'Coesfeld',
  'Cuxhaven',
  'Dachau',
  'Dahme-Spreewald',
  'Darmstadt-Dieburg',
  'Deggendorf',
  'Diepholz',
  'Dillingen an der Donau',
  'Dingolfing-Landau',
  'Dithmarschen',
  'Donau-Ries',
  'Donnersbergkreis',
  'Düren',
  'Ebersberg',
  'Eichsfeld',
  'Eichstätt',
  'Eifelkreis Bitburg-Prüm',
  'Elbe-Elster',
  'Emmendingen',
  'Emsland',
  'Ennepe-Ruhr-Kreis',
  'Enzkreis',
  'Erding',
  'Erlangen-Höchstadt',
  'Erzgebirgskreis',
  'Esslingen',
  'Euskirchen',
  'Forchheim',
  'Freising',
  'Freudenstadt',
  'Freyung-Grafenau',
  'Friesland',
  'Fulda',
  'Fürstenfeldbruck',
  'Fürth',
  'Garmisch-Partenkirchen',
  'Germersheim',
  'Gießen',
  'Gifhorn',
  'Göppingen',
  'Görlitz',
  'Goslar',
  'Gotha',
  'Göttingen',
  'Grafschaft Bentheim',
  'Greiz',
  'Groß-Gerau',
  'Günzburg',
  'Gütersloh',
  'Hameln-Pyrmont',
  'Hannover',
  'Harburg',
  'Harz',
  'Haßberge',
  'Havelland',
  'Heidekreis',
  'Heidenheim',
  'Heilbronn',
  'Heinsberg',
  'Helmstedt',
  'Herford',
  'Hersfeld-Rotenburg',
  'Herzogtum Lauenburg',
  'Hildburghausen',
  'Hildesheim',
  'Hochsauerlandkreis',
  'Hochtaunuskreis',
  'Hof',
  'Hohenlohekreis',
  'Holzminden',
  'Höxter',
  'Ilm-Kreis',
  'Jerichower Land',
  'Kaiserslautern',
  'Karlsruhe',
  'Kassel',
  'Kelheim',
  'Kitzingen',
  'Kleve',
  'Konstanz',
  'Kronach',
  'Kulmbach',
  'Kusel',
  'Kyffhäuserkreis',
  'Lahn-Dill-Kreis',
  'Landsberg am Lech',
  'Landshut',
  'Leer',
  'Leipzig',
  'Lichtenfels',
  'Limburg-Weilburg',
  'Lindau',
  'Lippe',
  'Lörrach',
  'Lüchow-Dannenberg',
  'Ludwigsburg',
  'Ludwigslust-Parchim',
  'Lüneburg',
  'Main-Kinzig-Kreis',
  'Main-Spessart',
  'Main-Tauber-Kreis',
  'Main-Taunus-Kreis',
  'Mainz-Bingen',
  'Mansfeld-Südharz',
  'Marburg-Biedenkopf',
  'Märkischer Kreis',
  'Märkisch-Oderland',
  'Mayen-Koblenz',
  'Mecklenburgische Seenplatte',
  'Meißen',
  'Merzig-Wadern',
  'Mettmann',
  'Miesbach',
  'Miltenberg',
  'Minden-Lübbecke',
  'Mittelsachsen',
  'Mühldorf am Inn',
  'München',
  'Neckar-Odenwald-Kreis',
  'Neu-Ulm',
  'Neuburg-Schrobenhausen',
  'Neumarkt in der Oberpfalz',
  'Neunkirchen',
  'Neustadt an der Aisch-Bad Windsheim',
  'Neustadt an der Waldnaab',
  'Neuwied',
  'Nienburg/Weser',
  'Nordfriesland',
  'Nordhausen',
  'Nordsachsen',
  'Nordwestmecklenburg',
  'Northeim',
  'Nürnberger Land',
  'Oberallgäu',
  'Oberbergischer Kreis',
  'Oberhavel',
  'Oberspreewald-Lausitz',
  'Odenwaldkreis',
  'Oder-Spree',
  'Offenbach',
  'Oldenburg',
  'Olpe',
  'Ortenaukreis',
  'Osnabrück',
  'Ostalbkreis',
  'Ostallgäu',
  'Osterholz',
  'Ostholstein',
  'Ostprignitz-Ruppin',
  'Paderborn',
  'Passau',
  'Peine',
  'Pfaffenhofen an der Ilm',
  'Pinneberg',
  'Plön',
  'Potsdam-Mittelmark',
  'Prignitz',
  'Rastatt',
  'Ravensburg',
  'Recklinghausen',
  'Regen',
  'Regensburg',
  'Rems-Murr-Kreis',
  'Rendsburg-Eckernförde',
  'Reutlingen',
  'Rhein-Erft-Kreis',
  'Rheingau-Taunus-Kreis',
  'Rhein-Hunsrück-Kreis',
  'Rheinisch-Bergischer Kreis',
  'Rhein-Kreis Neuss',
  'Rhein-Lahn-Kreis',
  'Rhein-Neckar-Kreis',
  'Rhein-Pfalz-Kreis',
  'Rhein-Sieg-Kreis',
  'Rhön-Grabfeld',
  'Rosenheim',
  'Rostock',
  'Rotenburg',
  'Roth',
  'Rottal-Inn',
  'Rottweil',
  'Saale-Holzland-Kreis',
  'Saalekreis',
  'Saale-Orla-Kreis',
  'Saalfeld-Rudolstadt',
  'Saarbrücken',
  'Saarlouis',
  'Saarpfalz-Kreis',
  'Sächsische Schweiz-Osterzgebirge',
  'Salzlandkreis',
  'Schaumburg',
  'Schleswig-Flensburg',
  'Schmalkalden-Meiningen',
  'Schwalm-Eder-Kreis',
  'Schwandorf',
  'Schwarzwald-Baar-Kreis',
  'Schwäbisch Hall',
  'Schweinfurt',
  'Segeberg',
  'Siegen-Wittgenstein',
  'Sigmaringen',
  'Soest',
  'Sömmerda',
  'Sonneberg',
  'Spree-Neiße',
  'St. Wendel',
  'Stade',
  'Starnberg',
  'Steinburg',
  'Steinfurt',
  'Stendal',
  'Stormarn',
  'Straubing-Bogen',
  'Südliche Weinstraße',
  'Südwestpfalz',
  'Teltow-Fläming',
  'Tirschenreuth',
  'Traunstein',
  'Trier-Saarburg',
  'Tübingen',
  'Tuttlingen',
  'Uckermark',
  'Uelzen',
  'Unna',
  'Unstrut-Hainich-Kreis',
  'Unterallgäu',
  'Vechta',
  'Verden',
  'Viersen',
  'Vogelsbergkreis',
  'Vogtlandkreis',
  'Vorpommern-Greifswald',
  'Vorpommern-Rügen',
  'Vulkaneifel',
  'Waldeck-Frankenberg',
  'Waldshut',
  'Warendorf',
  'Wartburgkreis',
  'Weilheim-Schongau',
  'Weimarer Land',
  'Weißenburg-Gunzenhausen',
  'Werra-Meißner-Kreis',
  'Wesel',
  'Wesermarsch',
  'Westerwaldkreis',
  'Wetteraukreis',
  'Wittenberg',
  'Wittmund',
  'Wolfenbüttel',
  'Wunsiedel im Fichtelgebirge',
  'Würzburg',
  'Zollernalbkreis',
  'Zwickau'
]
elenco_iniziale.each do |who|
  d = PageDownloader.new(who: who)
  results << d.contacts
  puts "#{results.length}/#{elenco_iniziale.length}"
end

results = results.flatten.uniq { |s| s.azienda }
results = results.reject { |s| s.email == '' and s.email_da_sito == '' }

FileUtils.rm_rf("./output.csv")
CSV.open("./output.csv", "wb") do |csv|

  csv << ['chiave_ricerca', 'pagine_gialle', 'azienda', 'indirizzo', 'cap', 'citta', 'telefono', 'fax', 'email', 'web', 'email_da_sito']
  results.each do |c|
    csv << c.to_csv
  end

end
