# Testing

Caffeinate ships with some RSpec matchers for convenience.

## Check if an action unsubscribed someone from a campaign

```ruby
expect { campaign.unsubscribe(company, user: user) }.to unsubscribe_from_caffeinate_campaign campaign, company, user: user

```

## Check if an action subscribed someone to a campaign

```ruby
expect { campaign.subscribe(company, user: user) }.to subscribe_to_caffeinate_campaign campaign, company, user: user
```

## Check if someone is subscribed to a campaign

```ruby
campaign.subscribe(user)

expect(user).to be_subscribed_to_caffeinate_campaign campaign
```

This will check if they are subscribed as a `subscriber` relation (polymorphic). To add arguments:

```ruby
campaign.subscribe(company)

expect(company).to be_subscribed_to_caffeinate_campaign(campaign).with(user: user)
```

## Check if an action resulted in a campaign subscription being ended

```ruby
expect { campaign.subscribe(company, user: user).end! }.to end_caffeinate_campaign_subscription campaign, company, user: user
```
