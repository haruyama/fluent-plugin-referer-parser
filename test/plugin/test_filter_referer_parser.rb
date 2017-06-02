require 'helper'
require 'fluent/test/driver/filter'
require 'fluent/plugin/filter_referer_parser'

class RefererParserFilterTest < Test::Unit::TestCase
  # through & merge
  CONFIG1 = %(
    key_name referer
    remove_prefix test
    add_prefix merged
  )

  CONFIG2 = %(
    key_name ref
    out_key_known        ref_known
    out_key_referer      ref_referer
    out_key_host         ref_host
    out_key_search_term  ref_search_term
  )

  CONFIG3 = %(
    type referer_parser
    key_name ref
    referers_yaml test/data/referers.yaml
    encodings_yaml test/data/encodings.yaml
  )

  def setup
    Fluent::Test.setup
  end

  def create_driver(conf = CONFIG1)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::RefererParserFilter).configure(conf)
  end

  def filter(config, messages)
    d = create_driver(config)
    time = Time.parse('2012-07-20 16:40:30').to_i
    d.run(default_tag: 'test') do
      messages.each do |message|
        d.feed(time, message)
      end
    end
    d.filtered_records
  end

  sub_test_case 'configure' do
    test 'through & merge' do
      d = create_driver CONFIG1
      assert_equal 'referer', d.instance.key_name

      assert_equal 'referer_known',       d.instance.out_key_known
      assert_equal 'referer_referer',     d.instance.out_key_referer
      assert_equal 'referer_search_term', d.instance.out_key_search_term
    end

    test 'filter & merge' do
      d = create_driver CONFIG2
      assert_equal 'ref',    d.instance.key_name

      assert_equal 'ref_known',       d.instance.out_key_known
      assert_equal 'ref_referer',     d.instance.out_key_referer
      assert_equal 'ref_search_term', d.instance.out_key_search_term
    end
  end

  sub_test_case 'filter' do
    test 'through & merge' do
      messages = [
        { 'value' => 0 },
        { 'value' => 1, 'referer' => 'http://www.google.com/search?q=gateway+oracle+cards+denise+linn&hl=en&client=safari' },
        { 'value' => 2, 'referer' => 'http://www.unixuser.org/' },
        { 'value' => 3, 'referer' => 'http://www.google.co.jp/search?hl=ja&ie=Shift_JIS&c2coff=1&q=%83%7D%83%8B%83%60%83L%83%83%83X%83g%81@%8Aw%8Em%98_%95%B6&lr=' },
        { 'value' => 4, 'referer' => 'http://www.google.co.jp/search?hl=ja&ie=Shift_J&c2coff=1&q=%83%7D%83%8B%83%60%83L%83%83%83X%83g%81@%8Aw%8Em%98_%95%B6&lr=' },
        { 'value' => 5, 'referer' => 'http://search.yahoo.co.jp/search?p=%E3%81%BB%E3%81%92&aq=-1&oq=&ei=UTF-8&fr=sfp_as&x=wrt' },
      ]
      expected = [
        {
          'value' => 0,
          'referer_known' => false
        },
        {
          'value' => 1,
          'referer' => 'http://www.google.com/search?q=gateway+oracle+cards+denise+linn&hl=en&client=safari',
          'referer_known' => true,
          'referer_referer' => 'Google',
          'referer_host' => 'www.google.com',
          'referer_search_term' => 'gateway oracle cards denise linn'
        },
        {
          'value' => 2,
          'referer' => 'http://www.unixuser.org/',
          'referer_known' => false
        },
        {
          'value' => 3,
          'referer' => 'http://www.google.co.jp/search?hl=ja&ie=Shift_JIS&c2coff=1&q=%83%7D%83%8B%83%60%83L%83%83%83X%83g%81@%8Aw%8Em%98_%95%B6&lr=',
          'referer_known' => true,
          'referer_referer' => 'Google',
          'referer_host' => 'www.google.co.jp',
          'referer_search_term' => 'マルチキャスト　学士論文'
        },
        # invalid input_encoding
        {
          'value' => 4,
          'referer' => 'http://www.google.co.jp/search?hl=ja&ie=Shift_J&c2coff=1&q=%83%7D%83%8B%83%60%83L%83%83%83X%83g%81@%8Aw%8Em%98_%95%B6&lr=',
          'referer_known' => true,
          'referer_referer' => 'Google',
          'referer_host' => 'www.google.co.jp',
          'referer_search_term' => 'マルチキャスト　学士論文'.encode("Shift_JIS").force_encoding("US-ASCII")
        },
        {
          'value' => 5,
          'referer' => 'http://search.yahoo.co.jp/search?p=%E3%81%BB%E3%81%92&aq=-1&oq=&ei=UTF-8&fr=sfp_as&x=wrt',
          'referer_known' => true,
          'referer_referer' => 'Yahoo!',
          'referer_host' => 'search.yahoo.co.jp',
          'referer_search_term' => 'ほげ'
        }
      ]
      filtered = filter(CONFIG1, messages)
      assert_equal(expected, filtered)
    end

    test 'filter & merge' do
      messages = [
        { 'value' => 0 },
        { 'value' => 1, 'ref' => 'http://www.google.com/search?q=gateway+oracle+cards+denise+linn&hl=en&client=safari' },
        { 'value' => 2, 'ref' => 'http://www.unixuser.org/' },
        { 'value' => 3, 'ref' => 'https://www.google.com/search?q=%E3%81%BB%E3%81%92&ie=utf-8&oe=utf-8' }
      ]
      expected = [
        {
          'value' => 0,
          'ref_known' => false
        },
        {
          'value' => 1,
          'ref' => 'http://www.google.com/search?q=gateway+oracle+cards+denise+linn&hl=en&client=safari',
          'ref_known' => true,
          'ref_referer' => 'Google',
          'ref_host' => 'www.google.com',
          'ref_search_term' => 'gateway oracle cards denise linn'
        },
        {
          'value' => 2,
          'ref' => 'http://www.unixuser.org/',
          'ref_known' => false,
        },
        {
          'value' => 3,
          'ref' => 'https://www.google.com/search?q=%E3%81%BB%E3%81%92&ie=utf-8&oe=utf-8',
          'ref_known' => true,
          'ref_referer' => 'Google',
          'ref_host' => 'www.google.com',
          'ref_search_term' => 'ほげ'
        }
      ]
      filtered = filter(CONFIG2, messages)
      assert_equal(expected, filtered)
    end

    test 'file' do
      messages = [
        { 'value' => 0 },
        { 'value' => 1, 'ref' => 'http://ezsch.ezweb.ne.jp/search/?sr=0101&query=aiueo%20%95a%93I' },
        { 'value' => 2, 'ref' => 'http://ezsch.ezweb.ne.jp/search/ezGoogleMain.php?query=%83%8D' },
        { 'value' => 3, 'ref' => 'http://www.google.co.jp/search?hl=ja&ie=Shift_JIS&c2coff=1&q=%83%7D%83%8B%83%60%83L%83%83%83X%83g%81@%8Aw%8Em%98_%95%B6&lr=' }
      ]
      expected = [
        {
          'value' => 0,
          'referer_known' => false
        },
        {
          'value' => 1,
          'ref' => 'http://ezsch.ezweb.ne.jp/search/?sr=0101&query=aiueo%20%95a%93I',
          'referer_known' => true,
          'referer_referer' => 'Ezweb',
          'referer_host' => 'ezsch.ezweb.ne.jp',
          'referer_search_term' => 'aiueo 病的'
        },
        {
          'value' => 2,
          'ref' => 'http://ezsch.ezweb.ne.jp/search/ezGoogleMain.php?query=%83%8D',
          'referer_known' => true,
          'referer_referer' => 'Ezweb',
          'referer_host' => 'ezsch.ezweb.ne.jp',
          'referer_search_term' => 'ロ'
        },
        {
          'value' => 3,
          'ref' => 'http://www.google.co.jp/search?hl=ja&ie=Shift_JIS&c2coff=1&q=%83%7D%83%8B%83%60%83L%83%83%83X%83g%81@%8Aw%8Em%98_%95%B6&lr=',
          'referer_known' => true,
          'referer_referer' => 'Google',
          'referer_host' => 'www.google.co.jp',
          'referer_search_term' => 'マルチキャスト　学士論文'
        }
      ]
      filtered = filter(CONFIG3, messages)
      assert_equal(expected, filtered)
    end
  end
end
