# Caffeinate

Caffeinate is a Rails engine for managing the lifecycle of scheduled events. Most commonly, these events are sending emails for things such as a drip marketing campaign, but Caffeinate can schedule for anything.

Caffeinate provides a simple DSL to create sequences and doesn't hijack the rest of your application.&#x20;

### Do you suffer from ActionMailer tragedies?&#x20;

If you have _anything_ like this is your codebase, **you need Caffeinate**:\


```ruby
class User < ApplicationRecord
  after_commit on: :create do
    UserOnboardingMailer.welcome_to_my_cool_app(self).deliver_later
    UserOnboardingMailer.some_cool_tips(self).deliver_later(wait: 2.days)
    UserOnboardingMailer.help_getting_started(self).deliver_later(wait: 3.days)
  end
end
```

```ruby
class UserOnboardingMailer < ActionMailer::Base
  def welcome_to_my_cool_app(user)
    mail(to: user.email, subject: "Welcome to CoolApp!")
  end

  def some_cool_tips(user)
    return if user.unsubscribed_from_onboarding_campaign?

    mail(to: user.email, subject: "Here are some cool tips for MyCoolApp")
  end

  def help_getting_started(user)
    return if user.unsubscribed_from_onboarding_campaign?
    return if user.onboarding_completed?

    mail(to: user.email, subject: "Do you need help getting started?")
  end
end
```

#### What's wrong with this?

1. You're checking state in a mailer,
2. The unsubscribe feature is, most likely, tied to a `User` which means it's going to be very fun to scale when you need to add more unsubscribe links for different types of sequences,
   1. such as "one of your subscriptions have expired" but then you need to add a column to `Subscription` and the whole thing becomes a mess,
      1. which then means you need to check the state in that mailer...
         1. infinite loop

### Do it better in 2 minutes and 42 seconds

In three minutes, you can implement this onboarding Campaign with Caffeinate!

#### 1. Install Caffeinate

```
$ bundle add caffeinate
$ rails g caffeinate:install
$ rails db:migrate
```

#### 2. Create a Dripper

In your newly-created `app/drippers` directory, create `user_onboarding_dripper.rb`:

```ruby
class UserOnboardingDripper < ApplicationDripper
  # each sequence is a campaign. This will dynamically create one by the given slug
  self.campaign = :user_onboarding 
  
  # gets called before every time we process a drip
  before_drip do |_drip, mailing| 
    if mailing.subscription.subscriber.onboarding_completed?
      mailing.subscription.unsubscribe!("Completed onboarding")
      throw(:abort)
    end 
  end
  
  # map drips to the mailer
  drip :welcome_to_my_cool_app, mailer_class: 'UserOnboardingMailer', delay: 0.hours
  drip :some_cool_tips, mailer_class: 'UserOnboardingMailer', delay: 2.days
  drip :help_getting_started, mailer_class: 'UserOnboardingMailer', delay: 3.days
end
```

#### 3. Subscribe a User to the Dripper

<pre class="language-ruby"><code class="lang-ruby"><strong>class User &#x3C; ApplicationRecord
</strong>  after_commit on: :create do
    OnboardingDripper.subscribe!(self)
  end
end
</code></pre>

#### 4. Clean up and adjust the mailer argument

Your mailer argument will be sent a `Caffeinate::Mailing` object which has a user associated to it as a `subscriber`:

```ruby
class UserOnboardingMailer < ActionMailer::Base
  def welcome_to_my_cool_app(mailing)
    @mailing = mailing 
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Welcome to CoolApp!")
  end

  def some_cool_tips(mailing)
    @mailing = mailing 
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Here are some cool tips for MyCoolApp")
  end

  def help_getting_started(mailing)
    @mailing = mailing 
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Do you need help getting started?")
  end
end
```

Make sure to provide a link to unsubscribe from this drip campaign using `<%= caffeinate_unsubscribe_url %>` in your templates.&#x20;

#### 5. Run the Dripper

This is usually done in a periodic background job or cronjob. Caffeinate doesn't ship with its own process.

```
UserOnboardingDripper.perform!
```

### But wait, there's more

Caffeinate also...

* Allows for hyper-precise scheduled times: 9:19AM _in the user's timezone_? Sure! **Only on holidays?** YES!
* Periodical support
* Works with multiple associations
* Unsubscribe, resubscribe, re-unsubscribe, admin unsubscribe, subscribe again
* Effortlessly handle complex workflows and skip certain mailings while keeping a `CampaignSubscription` active

### Documentation

* Getting started, tips, and tricks
* Better-than-average code documentation

### Alternatives

Did I not pass your screener? To each their own. Check out these alternatives:

* [https://github.com/honeybadger-io/heya](https://github.com/honeybadger-io/heya) (wins the name award)
* [https://github.com/tarr11/dripper](https://github.com/tarr11/dripper) (awkward)
* [https://github.com/Sology/maily\_herald](https://github.com/Sology/maily\_herald) (lots of inspiration comes from here and I thought this was the coolest thing when I first started out with Rails)

### Contributing&#x20;

Please see [https://github.com/joshmn/caffeinate/blob/master/.github/contributing.md](https://github.com/joshmn/caffeinate/blob/master/.github/contributing.md)

### Thanks

* [https://github.com/sourdoughdev](https://github.com/sourdoughdev/caffeinate) for releasing the gem name to me
* [https://github.com/markokajzer](https://github.com/markokajzer) for listening to me talk about this most mornings

### License

[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)

\
[\
](https://github.com/tarr11/dripper)

\
