Report a batch of codeclimate results by merging and from multiple servers

Install
=======

```Bash
gem install codeclimate_batch
```

Usage
=====

```Ruby
# test_helper.rb
if ENV['CI']
  require 'codeclimate_batch'
  CodeclimateBatch.start
end
```

After tests have finished:

```Bash
# send all code climate reports to cc-amend, unifying them once 4 reports have come in
codeclimate-batch --groups 4
```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/codeclimate_batch.png)](https://travis-ci.org/grosser/codeclimate_batch)
