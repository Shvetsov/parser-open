class SroLso
  def initialize
    @host = 'http://sro-lso.ru/category'
    @list_of_links = 'http://sro-lso.ru/category/c_members'
    @required_fields = [
      :inn,
      :ogrn,
      :name,
      :short_name,
      :legal_address,
      :city,
      :certificate_number,
      :resolution_date,
      :status
    ]
    @links = []
    @data = []
  end

  def perform
    collect_links # Сбор ссылок
    iterate # Переход и сбор информации

    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_of_links))

    doc.css(".archive-table a").each do |link|
      @links.push link[:href]
    end

    while true
      next_link = doc.at_css('.paginav-next a') 
      if next_link
        doc = Nokogiri::HTML(open(next_link[:href]))
        doc.css(".archive-table a").each do |link|
          @links.push link[:href]
        end
      else 
        break
      end
    end
  end

  def iterate
    @links.each do |link|
      puts "start parsing #{link}"
      begin
        @html = Nokogiri::HTML(open(link)).css('#column').to_html
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send m #for status symbols
          value = '-' if (value.nil? or value.empty?)
          value.strip! if value.is_a? String
        rescue
          value = '-'
        end
        tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      puts "parsed"
    end
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @html.split('ИНН:</strong>')[1].split('<strong>')[0]
  end

  def ogrn
    raw = @html.split('Государственный регистрационный номер записи о государственной регистрации юридического лица:</strong>')[1].split('<strong>')[0]
  end

  def short_name
    raw = @html.split('Сокращенное наименование:</strong>')[1].split('<strong>')[0]
  end

  def name
    raw = @html.split('Сокращенное наименование:</strong>')[1].split('<strong>')[0]
  end

  def legal_address
    raw = @html.split('Место нахождения:</strong>')[1].split('<strong>')[0]
  end

  def city
    raw = @html.split('Место нахождения:</strong>')[1].split('<strong>')[0]
    test1 = raw.match /\b((пос|гор|пгт|рп|п\.г\.т)\. [А-Яа-яё\- ]+)\b/
    test2 = raw.match /\b((р.п.|рабочий поселок|город|село) [А-Яа-яё\- ]+)\b/
    test3 = raw.match /\b([гсдп]\. ?[А-Яа-яё\- ]+)\b/

    if raw[/москва/i]
      'г. Москва'
    elsif raw[/санкт ?\- ?петербург/i]
      'г. Санкт-Петербург'
    elsif test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def certificate_number
    raw = @html.split('Перечень видов работ, оказывающих влияние на безопасность объектов капитального строительства:</strong>')[1].split('<br>')[0]
    raw[/№ ?[\d.\-A-ZА-Я]+/]
  end

  def resolution_date
    raw = @html.split('Перечень видов работ, оказывающих влияние на безопасность объектов капитального строительства:</strong>')[1].split('<br>')[0]
    raw.split(' от ')[1].split('№')[0]
  end

  def status
    raw = @html.split('Основание прекращения членства:</strong>')[1].split('</div>')[0]
    raw.strip!
    raw.empty? ? :w : :e
  end
  
end

# SroLso.new.perform