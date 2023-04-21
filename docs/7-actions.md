# Actions

Actions allow you to integrate Caffeinate's timing logic with non-ActionMailer classes and methods.

## Compatability

* ✅ callbacks
* ✅ periodicals
* ❌ async delivery 

## Usage

We'll pretend that we have a custom SMS class that looks like this:

```ruby
class SMS
  attr_accessor :to, :body
  
  def send! 
    response = HTTParty.post("some-endpoint", body: { to: to, body: body}.to_json)
    raise HTTParty::ResponseError unless response.success? 
    
    true 
  end
end
```

### 1. Create a Dripper 

```ruby
class UserDripper < ApplicationDripper
  self.campaign = :user 
  
  drip :welcome, action_class: "UserAction", in: 5.minutes 
  drip :hows_it_going, action_class: "UserAction", in: 3.days 
  drip :upsell, action_class: "UserAction", in: 7.days 
end
```

Note here that we're using `action_class` instead of `mailer_class`. Everything else is the same, though.

### 2. Create a `Caffeinate::Action`

This is a special class that acts similarly to `ActionMailer::Base`. 

```ruby
class UserAction < Caffeinate::Action
  def welcome(mailing)
    user = mailing.subscriber

    message = SMS.new.tap do |sms|
      sms.to = user.phone_number
      sms.body = "Welcome to our app!"
    end

    message.send!
  end

  def hows_it_going(mailing)
    user = mailing.subscriber

    message = SMS.new.tap do |sms|
      sms.to = user.phone_number
      sms.body = "hey it's your account manager how's it going?!"
    end

    message.send!
  end
  
  def upsell(mailing)
    user = mailing.subscriber

    message = SMS.new.tap do |sms|
      sms.to = user.phone_number
      sms.body = "hey it's your account manager we're running out of money so can you change plans to make the investors happy?!"
    end

    message.send!
  end
end
```

And you're done! This will operate as Caffeinate normally does.

## Some special cases

### Using the methods for setup instead of outright-sending

You can use the method (`welcome`, `hows_it_going`, and `upsell`) to setup an object for delivery, which is ultimately executed by Caffeinate.

To do this, return an object that responds to `deliver!` in the method. This method must take an argument, which will be the instantiated `Action` object. This object will have two methods available that may be convenient to you: `action_name` and `caffeinate_mailing`.

`#deliver!` will be called immediately prior to marking the `Caffeinate::Mailing` as sent. If this raises an error, it will not be marked as sent.

Here's an example:

```ruby
class UserAction < Caffeinate::Action
  class Envelope
    def initialize(user)
      @sms = SMS.new
      @sms.to = user.phone_number 
    end
    
    def deliver!(action)
      # action will expose `#caffeinate_mailing` and `#action_name`
      @sms.body = # ... 
      @sms.send! 
    end
  end
  
  def welcome(mailing)
    user = mailing.subscriber

    Envelope.new(user)
  end

  def hows_it_going(mailing)
    user = mailing.subscriber
    
    Envelope.new(user)
  end
  
  def upsell(mailing)
    user = mailing.subscriber
    
    Envelope.new(user)
  end
end
```
