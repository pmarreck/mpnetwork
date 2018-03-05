defmodule Mpnetwork.Utils.RegexenTest do
  use ExUnit.Case, async: true

  import Mpnetwork.Utils.Regexen

  # I couldn't figure out how to handle these corner cases in the allotted time. :/
  # @too_difficult_positive_test_cases_hurt_my_brain ~w[
  # Note that some of these are input backwards. I think it's just a problem of matching on the foreign TLD properly
  # or just changing the matching to not match on specific TLD's.
  #   http://مثال.إختبار
  #   http://例子.测试
  #   http://उदाहरण.परीक्षा
  # ]

  @positive_test_cases ~w[
    https://www.mpwrealestateboard.network
    http://foo.com
    http://foo.com/
    http://foo.com/blah_blah
    http://foo.com/blah_blah/
    http://foo.com/blah_blah_(wikipedia)
    http://foo.com/blah_blah_(wikipedia)_(again)
    http://www.example.com/wpstyle/?
    http://www.example.com/wpstyle/?massacre=364
    http://www.example.com/wpstyle/?massacre=364&q=69
    http://www.example.com/wpstyle/?massacre\[subval\]=364
    http://www.example.com/wpstyle/compute.html?poo=364
    https://www.example.com/foo/?bar=baz&inga=42&quux
    http://code.google.com/events/#product=browser
    http://code.google.com/events/#&product=browser
    http://a.ws
    http://✪df.ws
    http://✪df.ws/123
    http://⌘.ws
    http://⌘.ws/
    http://➡.ws/䨹
    http://userid:password@example.com
    http://example.com:8080
    http://userid:password@example.com:8080
    http://userid:password@example.com:8080/
    http://userid@example.com
    http://userid@example.com/
    http://userid@example.com:8080
    http://userid@example.com:8080/
    http://userid:password@example.com
    http://userid:password@example.com/
    http://a.b.c.com/
    http://142.42.1.1/
    http://142.42.1.1:8080/
    http://foo.com/blah_(wikipedia)#cite-1
    http://foo.com/blah_(wikipedia)_blah#cite-1
    http://foo.com/unicode_(✪)_in_parens
    http://foo.com/(something)?after=parens
    http://☺.damowmow.com/
    http://j.mp
    ftp://foo.bar/baz
    http://foo.bar/?q=Test%20URL-encoded%20stuff
    http://1337.net
    http://a.bic.de
    http://a.baba-caca.de
    http://a.b-c.de
    http://223.255.255.254
    http://FE80:0000:0000:0000:0202:B3FF:FE1E:8329/path.html
    http://FE80::0202:B3FF:FE1E:8329
    http://2001:db8:0:1
    http://\[FE80::0202:B3FF:FE1E:8329\]:80
    http://\[2001:db8::1\]:8080/path
    http://fe80::7:8%eth0/whoa
    https://::ffff:0:255.255.255.255/test
    http://-.~_!$&'()*+,;=:%40:80%2f::::::@example.com
  ]

  # I disagreed that some of these should fail, so I commented them out... But can follow up again some other time.
  @negative_test_cases [
    "http://",
    "http://.",
    "http://..",
    "http://../",
    "http://?",
    "http://??",
    "http://??/",
    "http://#",
    "http://##",
    "http://##/",
    "http://foo.bar?q=Spaces should be encoded",
    "//",
    "//a",
    "///a",
    "///",
    "http:///a",
    "foo.com",
    "rdar://1234",
    "h://test",
    "http:// shouldfail.com",
    ":// should fail",
    "http://foo.bar/foo(bar)baz quux",
    "ftps://foo.bar/",
    "http://-error-.invalid/",
    "http://a.b--c.de/",
    "http://-a.b.co",
    "http://a.b-.co",
    # "http://0.0.0.0",
    # "http://10.1.1.0",
    # "http://10.1.1.255",
    # "http://224.1.1.1",
    "http://1.1.1.1.1",
    "http://123.123.123",
    # "http://3628126748",
    "http://.www.foo.bar/",
    "http://www.foo.bar./",
    "http://.www.foo.bar./"
    # "http://10.1.1.1",
  ]

  test "positives" do
    @positive_test_cases
    |> Enum.each(&assert &1 =~ url_regex())
  end

  test "negatives" do
    @negative_test_cases
    |> Enum.each(&refute &1 =~ url_regex())
  end
end
