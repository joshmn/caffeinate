# Without ActionMailer

As of Caffeinate v2.3.0, you can use Caffeinate without ActionMailer! Internally, these are called "Actions". Here's how to transition from an ActionMailer-based Drip to an Action-based Drip.

## Example using ActionMailer

Here's a normal Dripper:

```ruby
class OnboardingDripper < ApplicationDripper
  self.campaign = :onboarding 
  
  before_drip do |_drip, mailing| 
    if mailing.subscription.subscriber.onboarding_completed?
      mailing.subscription.unsubscribe!("Completed onboarding")
      throw(:abort)
    end 
  end
  
  # map drips to the mailer
  drip :welcome_to_my_cool_app, mailer: 'OnboardingMailer', delay: 0.hours
  drip :some_cool_tips, mailer: 'OnboardingMailer', delay: 2.days
  drip :help_getting_started, mailer: 'OnboardingMailer', delay: 3.days
end
```

With corresponding `OnboardingMailer`:

```ruby
class OnboardingMailer < ActionMailer::Base
  def welcome_to_my_cool_app(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Welcome to CoolApp!")
  end

  def some_cool_tips(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Here are some cool tips for MyCoolApp")
  end

  def help_getting_started(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Do you need help getting started?")
  end
end
```

To change our drips to a PORO-handled object, we need to:

1. Change each `drip` option `mailer` to `action_class` in `OnboardingDripper` to `OnboardingAction`
2. Rename `OnboardingMailer` to `OnboardingAction`
3. Have `OnboardingAction` inherit from `Caffeinate::ActionProxy`
4. Do something other than `mail`

### 1. Change drip option

```ruby
class OnboardingDripper < ApplicationDripper
  self.campaign = :onboarding 
  
  before_drip do |_drip, mailing| 
    if mailing.subscription.subscriber.onboarding_completed?
      mailing.subscription.unsubscribe!("Completed onboarding")
      throw(:abort)
    end 
  end
  
  # map drips to the mailer
  drip :welcome_to_my_cool_app, action_class: 'OnboardingAction', delay: 0.hours
  drip :some_cool_tips, action_class: 'OnboardingAction', delay: 2.days
  drip :help_getting_started, action_class: 'OnboardingAction', delay: 3.days
end
```

### 2. Rename OnboardingMailer

```ruby

class OnboardingAction < ActionMailer::Base
  def welcome_to_my_cool_app(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Welcome to CoolApp!")
  end

  def some_cool_tips(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Here are some cool tips for MyCoolApp")
  end

  def help_getting_started(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Do you need help getting started?")
  end
end
```

### 3. Change subclass

```ruby

class OnboardingMailer < Caffeinate::ActionProxy
  def welcome_to_my_cool_app(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Welcome to CoolApp!")
  end

  def some_cool_tips(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Here are some cool tips for MyCoolApp")
  end

  def help_getting_started(mailing)
    @user = mailing.subscriber
    mail(to: @user.email, subject: "Do you need help getting started?")
  end
end
```

### 4. Do something different than `mail`

```ruby
class OnboardingAction < ActionMailer::Base
  def welcome_to_my_cool_app(mailing)
    @user = mailing.subscriber
    post_to_api(to: @user.phone_number, content: "Welcome to CoolApp!")
  end

  def some_cool_tips(mailing)
    @user = mailing.subscriber
    post_to_api(to: @user.phone_number, content: "Here are some cool tips for MyCoolApp")
  end

  def help_getting_started(mailing)
    @user = mailing.subscriber
    post_to_api(to: @user.phone_number, content: "Do you need help getting started?")
  end
  
  private 
  
  def post_to_api(to:, content:)
    HTTParty.post # ... 
  end
end
```

Done! Everything is handled the same as it would be otherwise. Caffeinate will still mark them as sent after this action completes successfully.

If you need to bail, raise an error.

## Using the actions as setup

If you return an object that implements `#deliver!`, it will be called. Here's an example:

```ruby
class PostAPIDeliver
  def initialize(to:, content:)
    @to = to 
    @content = content 
  end
  
  def deliver!(_action)
    HTTParty.post # ...
  end
end

class OnboardingAction < ActionMailer::Base
  def welcome_to_my_cool_app(mailing)
    @user = mailing.subscriber
    post_to_api(to: @user.phone_number, content: "Welcome to CoolApp!")
  end

  def some_cool_tips(mailing)
    @user = mailing.subscriber
    post_to_api(to: @user.phone_number, content: "Here are some cool tips for MyCoolApp")
  end

  def help_getting_started(mailing)
    @user = mailing.subscriber
    post_to_api(to: @user.phone_number, content: "Do you need help getting started?")
  end
  
  private 
  
  def post_to_api(to:, content:)
    PostAPIDeliver.new(to: to, content: content)
  end
end
```

