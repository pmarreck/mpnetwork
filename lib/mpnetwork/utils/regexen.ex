defmodule Mpnetwork.Utils.Regexen do
  # taken from http://www.regular-expressions.info/email.html
  # Added A-Z to char classes to avoid having to use /i switch
  @email_regex_source Regex.replace(~r/\s+/, """
    (?=[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]{1,64}@)
    [A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*
    @ (?:(?=[A-Za-z0-9-]{1,63}\\.)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\\.)+
    (?=[A-Za-z0-9-]{1,63})[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?
  """, "")
  def email_regex, do: Regex.compile!("\\A" <> @email_regex_source <> "\\z")

  # This tries to parse an email address and name from an RFC 5322-formatted "to" header.
  # I invented this.
  # Note that multiple matches will have to be done multiple times.
  @email_parsing_regex_source """
    \\s*
    (?:
      (?:
        (?:"(?<name>[^"]+)")\\s*<(?<email>#{@email_regex_source})>
      )
    |
      (?<only_email>#{@email_regex_source})
    )(?:,\\s+|,|\\s+|\\b)?
  """
  def email_parsing_regex, do: Regex.compile!(Regex.replace(~r/\s+/, @email_parsing_regex_source, ""))

  # taken from... a bunch of sources and rfc's.
  @uri_regex ~r/^
    (?<scheme>
      \b
        (?> https? | mailto | [st]?ftp | aaas? | about | a?cap | cid | crid | data | dav | dict | dns | fax | file | geo | gopher | go | h323 | iax | icap | im | imap | info | ipp | iris | ldap | msrps? | news | nfs | nntp | pop | rsync | rtsp | sips? | sms | snmp | tag | telnet | tel | tip | tv | urn | uuid | view\-source | wss? | xmpp | aim | apt | afp | bitcoin | bolo | callto | chrome | content | cvs | doi | facetime | feed | finger | fish | git | gg | gizmoproject | gtalk | irc[s6]? | itms | jar | javascript | lastfm | ldaps | magnet | maps | market | message | mms | msnim | mumble | mvn | notes | palm | paparazzi | platform | proxy | psyc | query | rmi | rtmp | secondlife | sgn | skype | spotify | ssh | smb | soldat | steam | svn | teamspeak | things | udp | unreal | ventrilo | webcal | wtai | wyciwyg | xfire | xri | ymsgr)
      \b
      \:
    ){0}
    (?<scheme_separator>
      \/{0,3}
    ){0}
    (?<scheme_prefix>
      \g<scheme>
      \g<scheme_separator>
    ){0}
    (?<tld>
      \b
        (?> COM | ORG | EDU | GOV | UK | NETWORK | NET | CA | DE | JP | FR | AERO | ARPA | ASIA | A[UCDEFGILMNOQRSTWXZ] | US | RU | CH | IT | NL | SE | NO | ES | MIL | BIZ | B[ABDEFGHIJMNORSTVWYZ]R? | CAT | COOP | C[CDFGIKLMNORUVWXYZ] | D[JKMOZ] | E[CEGRTU] | F[IJKMO] | G[ABDEFGHILMNPQRSTUWY] | H[KMNRTU] | INFO | INT | I[DELMNOQRS] | JOBS | J[EMO] | K[EGHIMNPRWYZ] | L[ABCIKRSTUVY] | MOBI | MUSEUM | M[ACDEGHKLMNOPQRSTUVWXYZ] | NAME | N[ACEFGIPRUZ] | OM | PRO | P[AEFGHKLMNRSTWY] | QA | R[EOSW] | S[ABCDGHIJKLMNORTUVXYZ] | TRAVEL | TEL | TLD | T[CDFGHJKLMNOPRTVWZ] | U[AGYZ] | VET | V[ACEGINU] | WIKI | W[FS] | XN\-\- (?> 0ZWM56D | 11B5BS3A9AJ6G | 3E0B707E | 45BRJ9C | 80AKHBYKNJ4F | 80AO21A | 90A3AC | 9T4B11YI5A | CLCHC0EA0B2G2A9GCD | DEBA0AD | FIQS8S | FIQZ9S | FPCRJ9C3D | FZC2C9E2C | G6W251D | GECRJ9C | H2BRJ9C | HGBK6AJ7F53BBA | HLCJ6AYA9ESC7A | J6W193G | JXALPDLP | KGBECHTV | KPRW13D | KPRY57D | LGBBAT1AD8J | MGBAAM7A8H | MGBAYH7GPA | MGBBH1A71E | MGBC0A9AZCG | MGBERP4A5D4AR | O3CW4H | OGBPF8FL | P1AI | PGBS0DH | S9BRJ9C | WGBH1C | WGBL6A | XKC2AL3HYE2A | XKC2DL3A5EE0H | YFRO4I67O | YGBI2AMMX | ZCKZAH ) | XXX | Y[ET] | Z[AMW] )
      \b
    ){0}
    (?<ccsld>
      \g<tld>(?= [.]\g<tld>)
    ){0}
    (?<tlds>
      (?: [.]\g<ccsld>)? [.]\g<tld>
    ){0}
    (?<not_punc_char>
      [^\.\/\:\@\#\ \?\=\&\-\$]
    ){0}
    (?<allowed_name>
      (?:(?:\g<not_punc_char>\-\g<not_punc_char>)|\g<not_punc_char>){1,40}
    ){0}
    (?<subdomain_with_implicit_scheme>
      (?> w{2,3}\d{0,3} | mail | proxy | s[fm]tp | pop | ftp | irc | images | news | video )
      (?! \g<tlds> )
    ){0}
    (?<subdomain>
      (?! \g<subdomains_with_implicit_scheme> )
      \g<allowed_name>
      (?! \g<tlds> )
    ){0}
    (?<subdomains_with_implicit_scheme>
      \g<subdomain_with_implicit_scheme>(?: [.]\g<subdomain>){0,3}[.]
    ){0}
    (?<subdomains>
      \g<subdomain>(?: [.]\g<subdomain>){0,3}[.]
    ){0}
    (?<domain>
      \g<allowed_name>
      (?= \g<tlds> )
    ){0}
    (?<port>
      \d{1,5}
    ){0}
    (?<ipv4>
      ((25[0-5]|2[0-4][0-9]|[01]{0,1}[0-9][0-9]{0,1})\.){3,3}(25[0-5]|2[0-4][0-9]|[01]{0,1}[0-9][0-9]{0,1})
    ){0}
    (?<ipv6>
      # yeah I tried a lot of these, none were perfect, including the one I settled on (see failing test cases)
      # (?:(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){6})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:::(?:(?:(?:[0-9a-fA-F]{1,4})):){5})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){4})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,1}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){3})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,2}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){2})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,3}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:[0-9a-fA-F]{1,4})):)(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,4}(?:(?:[0-9a-fA-F]{1,4})))?::)(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,5}(?:(?:[0-9a-fA-F]{1,4})))?::)(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,6}(?:(?:[0-9a-fA-F]{1,4})))?::))))
      #(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))
      #(?>(?>([a-f0-9]{1,4})(?>:(?1)){7}|(?!(?:.*[a-f0-9](?>:|$)){8,})((?1)(?>:(?1)){0,6})?::(?2)?)|(?>(?>(?1)(?>:(?1)){5}:|(?!(?:.*[a-f0-9]:){6,})(?3)?::(?>((?1)(?>:(?1)){0,4}):)?)?(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(?>\.(?4)){3}))
      # (?:([0-9a-f]{1,4}:){1,1}(:[0-9a-f]{1,4}){1,6})|
      # (?:([0-9a-f]{1,4}:){1,2}(:[0-9a-f]{1,4}){1,5})|
      # (?:([0-9a-f]{1,4}:){1,3}(:[0-9a-f]{1,4}){1,4})|
      # (?:([0-9a-f]{1,4}:){1,4}(:[0-9a-f]{1,4}){1,3})|
      # (?:([0-9a-f]{1,4}:){1,5}(:[0-9a-f]{1,4}){1,2})|
      # (?:([0-9a-f]{1,4}:){1,6}(:[0-9a-f]{1,4}){1,1})|
      # (?:(([0-9a-f]{1,4}:){1,7}|:):)|
      # (?::(:[0-9a-f]{1,4}){1,7})|
      # (?:((([0-9a-f]{1,4}:){6})(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}))|
      # (?:(([0-9a-f]{1,4}:){5}[0-9a-f]{1,4}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}))|
      # (?:([0-9a-f]{1,4}:){5}:[0-9a-f]{1,4}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})|
      # (?:([0-9a-f]{1,4}:){1,1}(:[0-9a-f]{1,4}){1,4}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})|
      # (?:([0-9a-f]{1,4}:){1,2}(:[0-9a-f]{1,4}){1,3}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})|
      # (?:([0-9a-f]{1,4}:){1,3}(:[0-9a-f]{1,4}){1,2}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})|
      # (?:([0-9a-f]{1,4}:){1,4}(:[0-9a-f]{1,4}){1,1}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})|
      # (?:(([0-9a-f]{1,4}:){1,5}|:):(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})|
      # (?::(:[0-9a-f]{1,4}){1,5}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})
      # ((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?
      (?:
        ::(ffff(:0{1,4}){0,1}:){0,1}
        ((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}
        (25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|    # ::255.255.255.255   ::ffff:255.255.255.255  ::ffff:0:255.255.255.255  (IPv4-mapped IPv6 addresses and IPv4-translated addresses)
        ([0-9a-f]{1,4}:){1,4}:
        ((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}
        (25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|    # 2001:db8:3:4::192.0.2.33  64:ff9b::192.0.2.33 (IPv4-Embedded IPv6 Address)
        fe80:(:[0-9a-f]{1,4}){1,4}\%[0-9a-z]+|       # fe80::7:8%eth0   fe80::7:8%1     (link-local IPv6 addresses with zone index)
        (?:[0-9a-f]{0,4}:){1,6}[0-9a-f]{1,4}         # everything else lol
      )
    ){0}
    (?<hostname>
      (?: \g<subdomains>? \g<domain> \g<tlds>
        | \g<ipv4>
        | \g<ipv6>
        | \[ \g<ipv6> \] (?=\:\g<port>)          # ipv6 with port number needs to be in brackets
      )
    ){0}
    (?<hostname_with_implicit_scheme>
      \g<subdomains_with_implicit_scheme> \g<domain> \g<tlds>
    ){0}
    (?<host>
      \g<hostname>
      (?: \:\g<port>)?
    ){0}
    (?<host_with_implicit_scheme>
      \g<hostname_with_implicit_scheme>
      (?: \:\g<port>)?
    ){0}
    (?<username>
      [\.\-\pL\pN\~\_\!\$\&\'\(\)\*\+\,\;\=]{2,40}
    ){0}
    (?<password>
      [\pL\pN\,\.\:\<\>\;\'\"\\\[\]\{\}\|\`\~\!\?\#\$\%\^\&\*\(\)\-\=\_\+]{1,50}
    ){0}
    (?<userinfo>
      (?: \g<username>(?: \: \g<password> )? \@ )
    ){0}
    (?<authority>
      \g<userinfo>? \g<host>
    ){0}
    (?<authority_with_implicit_scheme>
      \g<userinfo>? \g<host_with_implicit_scheme>
    ){0}
    (?<hex>
      [0-9a-f]
    ){0}
    (?<disallowed_encoded>
      \%[01][0-9A-F]
    ){0}
    (?<hex_encoded>
      (?! \g<disallowed_encoded> )
      \%\g<hex>{2}
    ){0}
    (?<html_entity>
      \& (?> \#[0-9]{1,4} | \#x\g<hex>{1,4} | [a-z]{2,8} )\;
    ){0}
    (?<path_segment>
      (?: (?:(?![\&\#])[\pL&\pCs\pN\-\_\$\.\+\(\)\*\'\,\:\;\~\@✪]) | \g<hex_encoded> | \g<html_entity> ){1,200}
    ){0}
    (?<path>
      (?: \/ \g<path_segment>? ){0,10}
    ){0}
    (?<fragment>
      \# [^\ \#]*
    ){0}
    (?<querystring_name>
      \g<path_segment> (?: \[ \g<path_segment> \] )?
    ){0}
    (?<querystring_value>
      \g<path_segment>
    ){0}
    (?<name_value_pair>
      \g<querystring_name> (?: = \g<querystring_value> )?
    ){0}
    (?<name_value_pairs>
      \g<name_value_pair> (?: \& \g<name_value_pair>){0,20}
    ){0}
    (?<query>
      \? \g<name_value_pairs>?
    ){0}
    (?<locator>
      \g<path>? \g<query>? \g<fragment>?
    ){0}
    (?<URI>
      (?>
        \g<scheme_prefix> \g<authority>
      |
        \g<scheme_prefix>? \g<authority_with_implicit_scheme>
      )
      \g<locator>
    ){0}
    \g<URI>
  $/uix

  def uri_regex, do: @uri_regex
  def url_regex, do: @uri_regex
end
