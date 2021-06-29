# Funktor

It's like [Sidekiq](https://sidekiq.org/) for [AWS Lambda](https://aws.amazon.com/lambda/).

Execute your background jobs in Lambda for nearly instant and infinite scalability. This is ideal for
applications with uneven, unpredictable, or bursty usage patterns.

Coming Soon: Funktor Pro & Funktor Enterprise

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'funktor'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install funktor

## Initializing a new `funktor` app

Funktor uses [serverless](https://www.serverless.com/) to provision AWS resources and to deploy your
code to Lambda. You can install serverless by doing:

```
npm install -g serverless
```

Then you can initialize a new app by doing:

```bash
funktor bootstrap my-funktor-app
cd my-funktor-app
funktor init
```

Then you sh

This will create a `funktor` directory that is ready to deploy to AWS. If you've already configured
your aws tools via `~/.aws/credentials` you should be ready to deploy.

See the [wiki](https://github.com/Octo-Labs/funktor/wiki)
for more info, especially the
[section about getting started in a stand alone project](https://github.com/Octo-Labs/funktor/wiki/Getting-started-in-a-stand-alone-project).

## Deploying

After initialiing your app you can deploy it by `cd`ing into the `funktor` directory and using
`serverless deploy`.

```
cd funktor
serverless deploy --verbose
```

This will deploy to the `dev` stage. To deploy to a differnt stage you can use the `--stage` flag:

```
serverless deploy --stage production --verbose
```

After your app is deployed you'll see some outputs containing details about your AWS resources. The
primary ones you should look for are `IncomingJobQueueUrl`, `AccessKeyID`, and `SecretAccessKey`.
Those three pieces of info represent the primary interface to your `funktor` app from the outside world.

To push your first job to `funktor` you can make note of those values and then do something like this
in a `rails console`.

```ruby
ENV['FUNKTOR_INCOMING_JOB_QUEUE'] = "<Your IncomingJobQueueUrl>"
ENV['AWS_ACCESS_KEY_ID'] = "<Your AccessKeyID>"
ENV['AWS_SECRET_ACCESS_KEY'] = "<Your SecretAccessKey>"
ENV['AWS_REGION'] = "<Your AWS Region>" # 'us-east-1' by default

require_relative 'funktor/workers/hello_worker'
HelloWorker.perform_async
```

If everything went well you should see something like this:

```ruby
=> #<struct Aws::SQS::Types::SendMessageResult md5_of_message_body="...",
  md5_of_message_attributes=nil, md5_of_message_system_attributes=nil,
  message_id="...", sequence_number=nil>
```

## Writing Workers

```ruby
class HelloWorker
  include Funktor::Worker

  def perform(name)
    puts "hello #{name}"
  end
end
```

The arguments to your `perform` methos must be plain Ruby objects, and not complex objects like ActiveRecord
models. Funktor will dump the arguments to JSON when pushing the job onto the queue, so you need to make sure
that your arguments can be dumped to JSON and loaded back again without losing any information.

## Calling Workers

```ruby
HelloWorker.perform_async(name)
HelloWorker.perform_in(5.minutes, name)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Octo-Labs/funktor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/funktor/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Funktor project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Octo-Labs/funktor/blob/master/CODE_OF_CONDUCT.md).
