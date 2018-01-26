defmodule Mpnetwork.Search do

  def examples do
    """
    <br />
    <a id="toggle_examples" href="#">Click here for some example search queries</a>
    <br />
    <div id="examples" style="display: none">
    Get the latest listings: just hit return with an empty search field<br />
    By id number: <pre class="search_example">5</pre>
    By listing agent name or broker name (note that all searches are case-insensitive):<pre class="search_example">daniel gale</pre>
    By address fragment: <pre class="search_example">55 plandome</pre>
    By price range (searches both rental price and list price): <pre class="search_example">$500,000-1000000</pre>
    Listings owned by you: <pre class="search_example">my</pre><pre class="search_example">mine</pre>
    Listings owned by your office: <pre class="search_example">my office</pre>
    Manhasset school district: <pre class="search_example">SD6</pre>
    Port Washington school district: <pre class="search_example">SD4</pre>
    (You can also combine all of these with other filters like:)
    <pre class="search_example">my port washington</pre>
    <pre class="search_example">my 500,000-1,000,000</pre>
    <pre class="search_example">SD6 $500,000-$1,000,000 waterfront</pre>
    <pre class="search_example">my office UC</pre>
    <pre class="search_example">my office expired</pre>
    By listing status:<pre class="search_example">NEW</pre><pre class="search_example">new</pre> (or: FS, EXT, UC, CL, PC, WR, TOM) (or try:)<pre class="search_example">NEW or FS</pre>
    By expired: (anything that is EXP status or has an expiration date in the past; can be used with other filters like "my expired")<pre class="search_example">expired</pre>
    An exact phrase (include double quotes in this case!): <pre class="search_example">"manhasset high"</pre>
    A range on certain attributes: <pre class="search_example">3-5 bedroom or 2-4 garage</pre>
    Or specific values of those attributes: <pre class="search_example">6 room 3 bedroom colonial</pre>
    (Available attributes you can search for a range on are: room(s), bed/bedroom(s), bath/bathroom(s), fireplace(s), skylight(s), garage(s), family/families, story/stories)<br /><br />
    You can now also search on date ranges of listing start date, under contract date, and closing date. Examples follow (all case-insensitive):
    <pre class="search_example">FS: 12/1/2017-12/31/2017</pre>
    <pre class="search_example">for sale:12/1/2017 - 12/31/2017</pre>
    <pre class="search_example">UC: 12/1/2017-12/31/2017</pre>
    <pre class="search_example">under contract: 12/1/2017-12/31/2017</pre>
    <pre class="search_example">CL: 12/1/2017-12/31/2017</pre>
    <pre class="search_example">Closed: 12/1/2017-12/31/2017</pre>
    Searches default to all active listings only (listing status of NEW, FS, EXT, PC) unless you search on a specific listing status or set of statuses. If you want inactive/unavailable listings, add the word "inactive" or "unavailable" to the search.
    <pre class="search_example">inactive 1000000-2000000 3-5 bedroom 11050</pre>
    Comma-separated values are treated as "OR". So for example,
    <pre class="search_example">11050,11030</pre>
    will search for listings in Port Washington OR Manhasset.<br />
    You can search by almost any other attributes: <pre class="search_example">expired tudor waterfront (solar OR windmill) 500000-1000000</pre>
    When searching by multiple attributes, it filters on all of them, so <pre class="search_example">rent waterfront</pre> will find rentals on the waterfront (rent AND waterfront).<br />
    You can also use and, or, not (or the equivalent symbols &, |, !) and parentheses: <pre class="search_example">waterfront or colonial</pre>
    The only thing you can't currently do is a price range inside parenthetical groups with OR, so you CANNOT currently do something like (500000-1000000 or (my tudor)).<br />
    </div>
    """
  end

end