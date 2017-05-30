require 'cgi'
require 'yaml'
require 'referer-parser'

class Fluent::RefererParserFilter < Fluent::Filter
  Fluent::Plugin.register_filter('referer_parser', self)

  config_param :key_name,       :string
  config_param :referers_yaml,  :string, default: nil
  config_param :encodings_yaml, :string, default: nil

  config_param :out_key_known,       :string, default: 'referer_known'
  config_param :out_key_referer,     :string, default: 'referer_referer'
  config_param :out_key_host,        :string, default: 'referer_host'
  config_param :out_key_search_term, :string, default: 'referer_search_term'

  def configure(conf)
    super

    @referer_parser = if @referers_yaml
                        RefererParser::Parser.new(@referers_yaml)
                      else
                        RefererParser::Parser.new
                      end

    if @encodings_yaml
      @encodings = YAML.load_file(@encodings_yaml)
    else
      @encodings = {}
    end
  end

  def filter(tag, time, record)
    begin
      parsed = @referer_parser.parse(record[@key_name])
      record[@out_key_known] = parsed[:known]
      if parsed[:known]
        search_term = parsed[:term]
        uri = URI.parse(parsed[:uri])
        host = uri.host
        parameters = CGI.parse(uri.query)
        input_encoding = @encodings[host] || parameters['ie'][0] || parameters['ei'][0]
        begin
          search_term = search_term.force_encoding(input_encoding).encode('utf-8') if input_encoding && /\Autf-?8\z/i !~ input_encoding
        rescue
          log.error('invalid referer: ' + uri.to_s)
        end
        record.merge!(
          @out_key_known       => true,
          @out_key_referer     => parsed[:source],
          @out_key_host        => host,
          @out_key_search_term => search_term
        )
      end
    rescue
      record[@out_key_known] = false
    end
    record
  end
end
