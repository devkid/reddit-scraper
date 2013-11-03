require 'json'
require 'net/http'
require 'optparse'
require 'open-uri'

$dls = 0
$skipped = 0

$options = {}
optparse = OptionParser.new do |opts|
	opts.banner = "Usage: reddit-scraper.rb [options] download-directory/"
	
	$options[:minx] = 1280
	opts.on('-x', '--minx XRES', "Minimum horizontal resolution [default = 1280]") do |x|
		$options[:minx] = x.to_i
	end
	
	$options[:miny] = 720
	opts.on('-y', '--miny YRES', "Minimum vertical resolution [default = 720]") do |y|
		$options[:miny] = y.to_i
	end
	
	$options[:ratiomin] = nil
	opts.on('--ratio-min MIN', "Minimum aspect ratio") do |r|
		$options[:ratiomin] = r.to_f
	end
	
	$options[:ratiomax] = nil
	opts.on('--ratio-max MAX', "Maximum aspect ratio") do |r|
		$options[:ratiomax] = r.to_f
	end
	
	$options[:prefix] = ""
	opts.on('-p', '--prefix PREFIX', "filename prefix") do |p|
		$options[:prefix] = p
	end
	
	$options[:keep] = 20
	opts.on('-k', '--keep NUMBER', "only keep NUMBER of pictures, if <= 0: keep everything") do |k|
		$options[:keep] = k.to_i
	end
	
	$options[:upvotes] = nil
	opts.on('-u', '--upvotes NUMBER', "only pictures with at least NUMBER of upvotes") do |u|
		$options[:upvotes] = u.to_i
	end
	
	$options[:subreddit] = "earthporn"
	opts.on('-s', '--subreddit SUBREDDIT', "download pictures from SUBREDDIT [default = earthporn]") do |s|
		$options[:subreddit] = s
	end
	
	$options[:category] = ""
	opts.on('-c', '--category CATEGORY', "download pictures from CATEGORY [default = hot]") do |c|
		$options[:category] = c
	end
	
	$options[:time] = "all"
	opts.on('-t', '--time TIME', "download pictures from TIME (only in top) [default = all]") do |t|
		$options[:time] = t
	end
	
	opts.on('-h', '--help', "display this help message") do
		puts opts
		exit
	end
end
optparse.parse!

$dir = ARGV[0] or raise ArgumentError.new "No download directory given\n\n" + optparse.to_s
Dir.mkdir($dir) unless File.exists?($dir)
$files = Dir[$dir + "/" + $options[:prefix] + "*"].count

resp = open("http://reddit.com/r/" + $options[:subreddit] +  "/" + $options[:category] + ".json?t=" + $options[:time]).read
json = JSON.parse(resp)


json["data"]["children"].each do |link|
	
	if $options[:keep] > 0 then
		if $dls + $skipped >= $options[:keep] then
			puts "Maximum number of downloads reached"
			break
		elsif $dls + $files > $options[:keep] then
			last = Dir[$dir + "/" + $options[:prefix] + "*"].sort_by {|f| File.mtime(f)}.first
			File.delete last
			$files -= 1
			puts "Maximum number of downloads to keep reached, deleting oldest download"
		end
	end
	
	data = link["data"]
	
	if data["domain"].to_s().match(/^self\.\w+$/) then
		next
	end
	
	if $options[:upvotes] != nil and data["ups"] < $options[:upvotes] then
		next
	end
	
	title = data["title"].to_s
	id    = data["id"].to_s
	url   = data["url"].to_s
	
	path = $dir + "/" + $options[:prefix] + id
	
	# extract resolution
	res = title.scan(/[\[|\(]\s?(\d+)\s?[x|×|X]\s?(\d+)\s?[\]|\)]/).first
	if res.empty? then
		next
	end
	x   = res[0].to_i
	y   = res[1].to_i
	
	ratio = x.to_f / y
	if $options[:ratiomin] != nil and ratio < $options[:ratiomin] then
		next
	end
	if $options[:ratiomax] != nil and ratio > $options[:ratiomax] then
		next
	end
	
	if !Dir.glob(path + ".*").empty? then
		puts "Skipped"
		$skipped += 1
		next
	end
	
	# directly downloadable?
	ext = url.scan(/\.(jpg|png)$/)
	if !ext.empty? then
		puts "Direct download"
		ext = ext[0][0]
		path += "." + ext
	elsif data["domain"] == "imgur.com" then
		puts "imgur.com download"
		u = open(url).read().scan(/<img src="\/\/i\.imgur\.com\/(\w+)\.(\w+)" /).first
		ext = u[1]
		url = "http://i.imgur.com/" + u[0] + "." + ext
		path += "." + ext
	end
	
	dl = open(url)
	if not ["image/jpeg", "image/png"].include?(dl.content_type) then
		next
	end
	open(path, "wb").write(dl.read())
	$dls += 1
end
