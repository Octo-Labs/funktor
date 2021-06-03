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

Describe how/why to structure the project as a sub folder of your rails app.

```bash
funktor init
```

This will create a `funktor` directory that is ready to deploy to AWS. If you've already configured
your aws tools via `~/.aws/credentials` you should be ready to deploy.

Funktor uses [serverless](https://www.serverless.com/) to provision AWS resources and to deploy your
code to Lambda.

`funktor/serverless.yml` is the main files you should use to configure your AWS resources and functions.

`funktor/resources` contains a few files that provision some AWS resources that are used by `funktor`.
* An SQS Queue for the "incoming jobs queue"
* A Dynamo DB table to allow queueing of jobs more than 15 minutes in the future (Funktor Pro)
* One or more SQS Queues for active jobs
* An IAM User with permission to push jobs to the incoming jobs queue
* A CloudWatch dashboard to let you keep tabs on your application

`funktor/lambda_handlers` contains some scripts that receive events from Lambda, then invoke `funktor` to
do various things:
* `active_job_handler.rb` executes your jobs
* `delayed_job_scheduler.rb` (Funktor Pro) pulls delayed jobs out of DynamoDB and places them on the active job queue.
* `incoming_job_handler.rb` receives incoming jobs and pushes them to DynamoDB for delayed execution or to the active job queue as appropriate.

`funktor/workers` is where your workers will live.

`funktor/Gemfile` is the `Gemfile` that contains the gems that are needed for your workers to execute
jobs. This should be the minimal set of gems you can get away with so that cold start times remain reasonable.

## Deploying

After initialiing your app you can deploy it by `cd`ing into the `funktor` directory and using
`serverless deploy`.

```
cd funktor
serverless deploy
```

This will deploy to the `dev` stage. To deploy to a differnt stage you can use the `--stage` flag:

```
serverless deploy --stage production
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
