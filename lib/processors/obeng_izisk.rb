class ObengIzisk
  def initialize
    # @list_link = 'http://www.obeng-izisk.ru/index.php/chlenstvo-v-sro/reestr-chlenov/'
    @host = 'http://ais.obeng.ru:86'
    @list_link = 'http://ais.obeng.ru:86/resstr/ireestr.html'
    @data_link_template = ''
    @required_fields = [
      :inn,
      :name,
      :short_name,
      :city,
      :status,
      :resolution_date,
      :legal_address,
      :certificate_number,
      :ogrn
    ]
    @data = []
  end

  def perform
    collect_links
    iterate
    @data
  end

  private

  def collect_links
    @links = []
    list_link = @list_link
    
    Capybara.visit(list_link)
    puts "LIST: #{list_link}"

    while true
      Capybara.all(:xpath, '//div[@class="dataTables_wrapper"]/table[@class="display"]/tbody/tr/td[1]/a').each do |link|
        @links << @host + link[:href]
      end

      paginate_button = Capybara.all(:xpath, '//span[@class="paginate_active"]/following::span[@class="paginate_button"]').first

      # break
      if paginate_button
        puts 'Loading page ' + paginate_button.text
        paginate_button.click
        wait_for_ajax
      else
        break
      end
    end
  end

  def iterate
    @links.each do |link|
      puts "Visit: #{link}"
      Capybara.visit(link)
      tmp = Hash.new
      @required_fields.each do |m|
        tmp.merge!(m => self.send(m))
      end

      @data << tmp if tmp[:status]
    end
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      active = Capybara.page.evaluate_script('jQuery.active')
      until active == 0
        active = Capybara.page.evaluate_script('jQuery.active')
      end
    end
  end

  ### Fields methods ####

  ## Required fields ##
  def inn
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/tbody/tr/td[contains(text(),"ИНН")]/following::td').first
    slice ? slice.text : "-"
  end

  def short_name
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/tbody/tr/td[contains(text(),"сокращенное наименование")]/following::td').first
    slice ? slice.text : "-"
  end

  def name
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/tbody/tr/td[contains(text(),"полное наименование")]/following::td').first
    slice ? slice.text : "-"
  end

  def city
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/tbody/tr/td[contains(text(),"место нахождения юридического лица")]/following::td').first
    address = slice ? slice.text : "-"
    /г\.[\ ]?([а-я\-\ ]+)[\.\,]+/i.match(address) ? "г. " + /г\.[\ ]?([а-я\-\ ]+)[\.\,]+/i.match(address)[1] : '-'
  end

  def status
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/tbody/tr/td[contains(text(),"сведения о действии свидетельства")]/following::td').first
    info = slice ? slice.text : "-"
    info == 'Допуск действует' ? :w : false
  end

  def resolution_date
    # ???
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/thead/tr/th[contains(text(),"номер свидетельства")]/ancestor::table/tbody/tr[last()]/td[2]').first
    puts slice.text
    slice ? slice.text : "-"
  end

  def legal_address
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/tbody/tr/td[contains(text(),"место нахождения юридического лица")]/following::td').first
    slice ? slice.text : "-"
  end

  def certificate_number
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/thead/tr/th[contains(text(),"номер свидетельства")]/ancestor::table/tbody/tr[last()]/td[1]').first
    puts slice.text
    slice ? slice.text : "-"
  end

  def ogrn
    slice = Capybara.all(:xpath, '//table[@class="stripy"]/tbody/tr/td[contains(text(),"ОГРН")]/following::td').first
    slice ? slice.text : "-"
  end
end