require 'cgi'
require 'yaml'
require 'referer-parser'

require 'fluent/plugin/input'

# Fluent::Plugin::RefererParserFilter filters Referer strings
class Fluent::Plugin::RefererParserFilter < Fluent::Plugin::Filter
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

    @encodings = if @encodings_yaml
                   YAML.load_file(@encodings_yaml)
                 else
                   {}
                 end
  end

  def get_search_term(search_term, uri)
    parameters = CGI.parse(uri.query)
    input_encoding = @encodings[uri.host] || parameters['ie'][0] || parameters['ei'][0]
    return search_term.force_encoding(input_encoding).encode('utf-8') if input_encoding && /\Autf-?8\z/i !~ input_encoding
    search_term
  end

  def filter(_tag, _time, record)
    begin
      parsed = @referer_parser.parse(record[@key_name])
      record[@out_key_known] = parsed[:known]
      if parsed[:known]
        uri = URI.parse(parsed[:uri])
        begin
          search_term = get_search_term(parsed[:term], uri)
        rescue
          search_term = parsed[:term]
          log.error('invalid referer: ' + uri.to_s)
        end
        record.merge!(
          @out_key_referer     => parsed[:source],
          @out_key_host        => uri.host,
          @out_key_search_term => search_term
        )
      end
    rescue
      record[@out_key_known] = false
    end
    record
  end
end
