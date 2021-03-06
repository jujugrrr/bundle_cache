require "digest"
require "aws-sdk"

module BundleCache
  def self.install
    architecture = `uname -m`.strip
    file_name = "#{ENV['BUNDLE_ARCHIVE']}-#{architecture}.tgz"
    digest_filename = "#{file_name}.sha2"
    bucket_name = ENV["AWS_S3_BUCKET"]

    AWS.config({
      :access_key_id => ENV["AWS_S3_KEY"],
      :secret_access_key => ENV["AWS_S3_SECRET"],
      :region => ENV["AWS_S3_REGION"] || "us-east-1"
    })
    s3 = AWS::S3.new
    bucket = s3.buckets[bucket_name]

    gem_archive = bucket.objects[file_name]
    hash_object = bucket.objects[digest_filename]

    Dir.chdir(ENV['HOME'])

    puts "=> Downloading the bundle"
    File.open("remote_#{file_name}", 'wb') do |file|
      gem_archive.read do |chunk|
        file.write(chunk)
      end
    end
    puts "  => Completed bundle download"

    puts "=> Extract the bundle"
    `tar -xf "remote_#{file_name}"`

    puts "=> Downloading the digest file"
    File.open("remote_#{file_name}.sha2", 'wb') do |file|
      hash_object.read do |chunk|
        file.write(chunk)
      end
    end
    puts "  => Completed digest download"

    puts "=> All done!"
  rescue AWS::S3::Errors::NoSuchKey
    puts "There's no such archive!"
  end

end