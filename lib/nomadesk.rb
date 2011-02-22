class Nomadesk
  class Token
    attr_accessor :key
    
    def initialize(username, password)
      res = Request.get!(:user => username, :pass => password, :params => { "Task" => "Logon" })
      @key = res['Token']
      
      self
    end
  end
  
  class ResponseError < StandardError
    def initialize(res, message="")
      super("Nomadesk::ResponseError: #{res.message} (#{res.status}) #{message}")
    end
  end
  
  class Response
    attr_reader :hash, :status, :message, :raw
    
    def initialize(xml)
      @raw = xml
      @hash = Hash.from_xml(xml)['Response']
      @status = @hash.delete('Status')
      @message = @hash.delete('Message')
      puts @raw
      
      self
    end
    
    def [](key)
      return @hash[key]
    end
  end
  
  class Request
    def self.get(options)
      url = generate_request_url(options)
      puts url
      xml = open(url).read
      Response.new(xml)
    end
    
    def self.get!(options)
      res = get(options)
      raise ResponseError.new(res) unless res.status == "1"
      
      res
    end
    
    def self.url_for(options)
      self.generate_request_url(options)
    end
    
    protected
      def self.generate_request_url(options)
        options[:params] ||= {}
        
        if options[:url]
          base = options[:url]
        else
          options[:protocol] ||= "https"
          options[:host]     ||= "secure.nomadesk.com"
          options[:path]     ||= "/nomadesk-ctrller/api.php"
          base = "#{options[:protocol]}://#{options[:host]}#{options[:path]}"
        end
        
        options[:params]['Task'] = options[:task] if options[:task]

        if options[:token] && options[:token].is_a?(Token)
          options[:params]["Token"] = options[:token].key
        elsif options[:user] && (options[:pass] || options[:password])
          options[:params].merge!("Email" => options[:user], "Password" => options[:pass] || options[:password])
        else
          raise ArgumentError.new("No authorization params were passed")
        end

        params = options[:params].collect { |k,v| "#{k}=#{v}" }.join("&")

        "#{base}?#{URI.escape params}"
      end
  end
  
  class Bucket
    attr_accessor :name, :label, :api_url
    
    def initialize(name, label, storage_api_url)
      @name = name
      @label = label
      @api_url = storage_api_url
    end
    
    def self.list_from_hash(hash_list)
      hash_list.map{|h| self.from_hash(h) }
    end
    
    def self.from_hash(hash)
      Bucket.new(hash['Name'], hash['Label'], hash['StorageApiUrl'])
    end
  end
  
  class Item
    attr_accessor :name, :path, :type, :modified
    
    def initialize(name, path, type, modified)
      @name = name
      @path = path
      @type = type
      @modified = modified
    end
    
    def is_folder?
      return type == 'folder'
    end
    
    def full_path
      return "#{path}#{name}"
    end
    
    def self.list_from_hash(hash_list)
      hash_list.map{|h| self.from_hash(h) }
    end
    
    def self.from_hash(hash)
      Item.new(
        hash['Name'],
        hash['Path'],
        hash['IsFolder'] == "true" ? 'folder' : hash['Type'],
        Time.at(hash['LastModifiedDstamp'].to_i)
      )
    end
  end
  
  def initialize(options)
    if options[:user] && (options[:pass] || options[:password])
      @user = options[:user]
      @pass = options[:pass] || options[:password]
    else
      raise ArgumentError.new("You must supply the :user and :pass parameters to Nomadesk")
    end
  end
  
  def token
    if @token
      @token
    else
      @token = Token.new(@user, @pass)
    end
  end
  
  def buckets
    res = task("GetFileservers")
    list = arrayify(res['Fileservers']['Fileserver'])
    Bucket.list_from_hash(list)
  end
  
  def list(bucket, path = '/')
    res = task('ls', :url => bucket.api_url, :params => {"FileserverName" => bucket.name, "Path" => path})
    list = arrayify(res['FileInfos']['FileInfo'])
    Item.list_from_hash(list)
  end
  alias_method :ls, :list
  
  def download_url(bucket, path)
    res = task_url('FileDownload', :url => bucket.api_url, :params => {"FileserverName" => bucket.name, "Path" => path})
  end
  
  protected
    def arrayify(object)
      case object
      when Hash then [object]
      when Array then object
      when nil then []
      else raise "Unexpected class for arrayify #{object.class}"
      end
    end
    
    def task_url(task, options)
      Request.url_for({:task => task, :token => token}.merge(options))
    end
    
    def task(task, options = {})
      res = Request.get!({:task => task, :token => token}.merge(options))
    end
end