 
##tag search

Searches vapps by tags(metadata) and allows user to perform operations on result set.

Run following from tag_search directory:

bundle exec thor runner:vapps <tag_criteria> <operation-to-perform>

####Example
<pre>
bundle exec thor runner:vapps 'ci:true shutdown:true' 'power_on'
</pre>
The tag_criteria is a list of multiple criterias seperated by space. The indivudual critera has tag name and value seperated by colon.
