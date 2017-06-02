# fluent-plugin-referer-parser, a plugin for [Fluentd](http://fluentd.org)

## RefererParserFilter

'fluent-plugin-referer-parser' is a Fluentd plugin to parse Referer strings, based on [tagomoris/fluent-plugin-woothee](https://github.com/tagomoris/fluent-plugin-woothee).
'fluent-plugin-referer-parser' uses [snowplow/referer-parser](https://github.com/snowplow/referer-parser).

## Requirements

| fluent-plugin-referer-parser | fluentd     | ruby   |
|------------------------------|-------------|--------|
| >= 0.1.0                     | >= v0.14.15 | >= 2.1 |
| < 0.1.0                      | >= v0.12.0  | >= 1.9 |

## Configuration

To add referer-parser result into matched messages:

    <filter>
      @type referer_parser
      key_name referer
    </match>

Output messages with tag 'merged.**' has 'referer_known', 'referer_referer' and 'referer_search_term' attributes. If you want to change attribute names, write configurations as below:

    <filter>
      @type referer_parser
      key_name ref
      out_key_known        ref_known
      out_key_referer      ref_referer
      out_key_host         ref_host
      out_key_search_term  ref_search_term
    </match>

If you want to use your own referers definition, you can use 'referers_yaml' attribute.
'referers_yaml' should be referers.yaml format of [snowplow/referer-parser](https://github.com/snowplow/referer-parser).

* [Sample](test/data/referers.yaml)

## Copyright

* Copyright (c) 2012- TAGOMORI Satoshi (tagomoris)
* Copyright (c) HARUYAMA Seigo
* License
  * Apache License, Version 2.0
