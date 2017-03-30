require_relative 'depends.rb'

$relevancelow = Array.new
$relevancemedium = Array.new
$relevancehigh = Array.new



class Result 
	# Assume it's totally irrelavent 
  @relevance = 0
  @descrip = ""
  @text = ""
  # Get text of result
  
  def initialize(startertext, descrip)
    @text = startertext
    @descrip = descrip
    getRelevance()
  end

  def getRelevance() 
  	# Common flag format = Bump it's relevance
  	if @text =~ /{[0-9a-zA-Z]}/
  		@relevance = 2
  		$relevancehigh.push(self)
  	elsif @text =~ /^[0-9a-zA-Z]*$/
      if @text == "" or @text == " "
      elsif @descrip == "md5" or @descrip == "sha1" 
        @relevance = 2
        $relevancehigh.push(self)
      elsif @descrip != "caesar"
    		@relevance = 1
    		$relevancemedium.push(self)        
      else
        @relevance = 0
        $relevancelow.push(self)
      end
  	else
  		@relevance = 0
  		$relevancelow.push(self)
  	end

  end
  # Allow relevance and text to be read
  attr_reader :text, :relevance, :descrip
end

class Problem 

	@problemtext = ""
	def initialize(text)
    @problemtext = text
  end

  def b64() 
  	begin 
  		Base64.decode64(@problemtext)
  		Result.new(Base64.decode64(@problemtext),"base64")
  		return Problem.new(Base64.decode64(@problemtext))
  	rescue
 			# Suppress
 			return Problem.new(nil)
  	end
  end

  def caesar(key)
  	begin

  		# Ripped AGGRESSIVELY from StackOverflow

		  alphabet  = Array('a'..'z')
		  non_caps  = Hash[alphabet.zip(alphabet.rotate(key))]
		  
		  alphabet = Array('A'..'Z')
		  caps     = Hash[alphabet.zip(alphabet.rotate(key))]
		  
		  encrypter = non_caps.merge(caps)
		  
		  data = @problemtext.chars.map { |c| encrypter.fetch(c, c) }
		  caesardata = data.join

  		Result.new(caesardata,"caesar")
  		newprob = Problem.new(caesardata)
      newprob.md5()
      return newprob
  	rescue
 			# Suppress
 		return Problem.new(nil)
  	end
  end

  def md5_dict(hash, wordlist)
    wordlist.each do |word|
      if Digest::MD5.hexdigest(word) == hash.downcase
        return word
      end
    end
    nil
  end

  def sha1_dict(hash, wordlist)
    wordlist.each do |word|
      if Digest::SHA1.hexdigest(word) == hash.downcase
        return word
      end
    end
    return nil
  end

  def md5()
  	hash = @problemtext
    response = HTTParty.get("http://google.com/search?q=#{hash}", headers: {"User-Agent" => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36'})
    if response.include? "sorry"
      puts "WARNING: SUSPECTED GOOGLE FLAGGING BOT TRAFFIC"
    end
    wordlist = response.split(/\s+/)
    if plaintext = md5_dict(hash, wordlist)
    	Result.new(plaintext,"md5")
      return Problem.new(plaintext)
    else 
    	return Problem.new(nil)
    end
  end

  def sha1()
    hash = @problemtext
    response = HTTParty.get("http://google.com/search?q=#{hash}", headers: {"User-Agent" => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36'})
    if response.include? "sorry"
      puts "WARNING: SUSPECTED GOOGLE FLAGGING BOT TRAFFIC"
    end
    wordlist = response.split(/\s+/)
    if plaintext = sha1_dict(hash, wordlist)
      Result.new(plaintext,"sha1")
      return Problem.new(plaintext)
    else 
      return Problem.new(nil)
    end
  end

  def allcaesar()
  	(1..25).each do |i|
  		self.caesar(i)
  	end
  end
  def hex2ascii()
  	begin
  				clean = @problemtext.delete(' ')
  				cleaner = clean.delete('\\')
					if cleaner =~ /^[0-9A-Fa-f]+$/
						s = cleaner.scan(/../).map { |x| x.hex.chr }.join
						Result.new(s,"hex2ascii")
						return Problem.new(s)
					end
  	rescue => e
  		# Suppress
  		return Problem.new(nil)
  	end
  end

  def b32()
  	begin
  		Base32.decode(@problemtext)
  		Result.new(Base32.decode(@problemtext),"base32")
  		return Problem.new(Base32.decode(@problemtext))
  	rescue
  		# Suppress
  		return Problem.new(nil)
  	end
  		
  end

  attr_reader :problemtext
end

problem = Problem.new(ARGV[0])
quiet = false
begin 
if ARGV[1] == "quiet"
quiet = true
end
rescue
quiet = false
end

problem.sha1()
problem.md5()
problem.hex2ascii()
problem.b32().b64()
problem.b64().b32()
problem.b64().allcaesar()


$relevancehigh.each do |res|
	puts "#{res.text} - Found via #{res.descrip} - HIGH RELEVANCE".colorize(:color => :light_red, :background => :black)
end

$relevancemedium.each do |res|
	puts "#{res.text} - Found via #{res.descrip} - MEDIUM RELEVANCE".colorize(:color => :light_yellow, :background => :black)
end
if quiet == false
  $relevancelow.each do |res|
  	puts "#{res.text} - Found via #{res.descrip} - LOW RELEVANCE".colorize(:color => :white, :background => :black)
  end
end