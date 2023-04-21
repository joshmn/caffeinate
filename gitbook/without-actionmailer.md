# Without ActionMailer

Caffeinates original use-case was to be used with `ActionMailer`, but can be used with any Ruby class thanks to `Caffeinate::Action`.

You can see this feature fleshed out here: [https://github.com/joshmn/caffeinate/pull/24](https://github.com/joshmn/caffeinate/pull/24)

### Basic setup

Let's pretend we have an onboarding campaign for a new `User` and we send them SMS via [Twilio](https://www.twilio.com/docs/sms/quickstart/ruby). This guide assumes you already have [Caffeinate installed](installation.md).

#### 1. Some setup (optional)

Let's have a clean space for these messages:

<pre class="language-ruby"><code class="lang-ruby">class SMS
  attr_accessor :to, :body 
  
  def send! 
    client.messages.create(
      from: '+15551234567', 
      to: to,
<strong>      body: body
</strong><strong>    )
</strong>  end 
  
  private 
  
  def client
    account_sid = 'ACxxxxxxxxxxxxxxxxxxxxxxxx'
<strong>    auth_token = 'yyyyyyyyyyyyyyyyyyyyyyyyy'
</strong><strong>    client = Twilio::REST::Client.new(account_sid, auth_token)
</strong>  end
end
</code></pre>

#### 2. Create a Dripper

```ruby
class UserOnboardingDripper < ApplicationDripper
  self.campaign = :user_onboarding 
  
  # map drips to the mailer
  drip :welcome_to_my_cool_app, action_class: 'UserOnboardingAction', delay: 0.hours
  drip :some_cool_tips, action_class: 'UserOnboardingAction', delay: 2.days
  drip :help_getting_started, action_class: 'UserOnboardingAction', delay: 3.days
end
```

The only thing different here is `action_class` instead of `mailer_class`.&#x20;

#### 3. Create a \`Caffeinate::Action\`

Next, let's create the corresponding `Caffeinate::Action`:

```ruby
class UserOnboardingAction < Caffeinate::Action
  def welcome_to_my_cool_app(mailing)
    user = mailing.subscriber
    message = SMS.new
    message.to = @user.phone_number
    message.body = "Welcome to CoolApp!"
    message.send!
  end

  def some_cool_tips(mailing)
    user = mailing.subscriber
    message = SMS.new
    message.to = user.phone_number
    message.body = "Here are some cool tips:"
    message.send!
  end

  def help_getting_started(mailing)
    user = mailing.subscriber
    message = SMS.new
    message.to = user.phone_number
    message.body = "Do you need help getting started?"
    message.send!
  end
end
```

This looks, feels, and acts just like `ActionMailer::Base`.

#### 4. Done!

You're all done. Just make sure you are running the dripper.

### Advanced

Our example above is fine, but we can DRY it up.

If the returning object from a `Caffeinate::Action` responds to `deliver!`, Caffeinate will invoke it and pass it the instantiated `Caffeinate::Action` object. Internally, we refer to this returning object as some sort of `Envelope`, but there's no special class for it.&#x20;

If this sounds confusing, well, it can be. Consider this model: A `Caffeinate::Action` is the equivalent to `ActionMailer::Base`, and the subsequent `Envelope` is a `Mail::Message`.&#x20;

Using this strategy can be useful for using the method as setup, and the `Envelope` handling delivery.

I personally like putting the `Envelope` (or whatever you'd want to call it) inside the action class.

```ruby
class UserOnboardingAction < Caffeinate::Action
  class Envelope
    def initialize(user)
      @user = user 
      @sms = SMS.new 
      @sms.to = @user.phone_number
    end
    
    # action will also contain the original mailing if you want it 
    # as the method #caffeinate_mailing
    def deliver!(action)
      if action.action_name == :welcome_to_my_cool_app
        # build body for welcome_to_my_cool_app
      elsif action.action_name == :some_cool_tips
      elsif action.action_name == :help_getting_started
      else
        raise ArgumentError, "unsure how to handle #{action.action_name}"
      end
     
      @sms.send!
    end
  end
  
  def welcome_to_my_cool_app(mailing)
    user = mailing.subscriber
    Envelope.new(user)
  end

  def some_cool_tips(mailing)
    user = mailing.subscriber
    Envelope.new(user)
  end

  def help_getting_started(mailing)
    user = mailing.subscriber
    Envelope.new(user)
  end
end
```

