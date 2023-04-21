# Getting Started

After you've installed Caffeinate, you'll need to create a `Dripper`.&#x20;

### Dripper

The concept of a `Dripper` is a collection of events that are associated with a `Caffeinate::Campaign`. By default, Caffeinate will try to automatically create the `Caffeinate::Campaign` by the slug given using `find_or_create_by`.

```
class OnboardingDripper < ApplicationDripper
  self.campaign = :onboarding
end
```

To add an event to this, such as sending a mail using `ActionMailer`, add a `drip`:

```
class OnboardingDripper < ApplicationDripper
  self.campaign = :onboarding
  
  drip :welcome, mailer_class: "OnboardingDripperMailer", in: 5.minutes
end
```

When a new User (or thing) subscribes to this `Caffeinate::Campaign` , Caffeinate will create a `Caffeinate::CampaignSubscription` object and collection of `Caffeinate::Mailing` objects that correspond to each `Drip`.&#x20;

Note: Caffeinate was originally intended for mailings only, but that has changed! `Caffeinate::Mailing` will be renamed to `Caffeinate::Event` in V3, which will be released... sometime in the future.

### Drip&#x20;

An event is called a `Drip`. A `Drip` has many options:
