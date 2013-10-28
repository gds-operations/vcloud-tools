 
##tag search

Searches vapps by tags(metadata) and allows user to perform operations on result set.

Run following from tag_search directory: `bundle exec thor runner:vapps <tag_criteria> <operation-to-perform>`

####Example

    bundle exec thor runner:vapps 'ci:true shutdown:true' 'power_on'

Would power on the set of vapps that have both the tags `ci` and `shutdown` set to true

The tag_criteria is a list of multiple criteria separated by space. The individual criteria has tag name and value separated by colon.
