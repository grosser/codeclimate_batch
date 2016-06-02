Report a batch of codeclimate results by merging and from multiple servers.<br/>
Uses [cc-amend](https://github.com/grosser/cc-amend) to do the merging since workers will not share a common disk.

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

 - Will only run when `ENV['CODECLIMATE_REPO_TOKEN']` is set and running on `master` branch
 - If your default branch is not `master`, set `ENV['DEFAULT_BRANCH']`

After tests have finished:

```Bash
# send coverage reports to cc-amend, unifying once 4 reports arrive
codeclimate-batch --groups 4

# custom key (when not using travis), must be the same on all hosts
codeclimate-batch --groups 4 --key my-app/$BUILD_NUMBER
```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/codeclimate_batch.png)](https://travis-ci.org/grosser/codeclimate_batch)
