def assert(left, right, message)
  ok = left == right
  p message unless ok
  p "#{left} != #{right}" unless ok
end

# Setup
p 'Setup'

Supplejack.api_key = ENV['SJ_CLIENT_TEST_KEY']
user = Supplejack::User.new(api_key: ENV['SJ_CLIENT_TEST_KEY'])
user.stories.each(&:destroy)
user.stories.fetch(force: true)

p 'Done Setup'

# Create story
p 'Create Story'

user.stories.create(name: 'Test story')

assert(user.stories.first.name, 'Test story', 'name of story does not match')

p 'Done Create Story'

# Update story
p 'Update Story'
user.stories.first.update_attributes(name: 'A new name', description: 'fizzle', tags: ['love', 'me', 'some', 'tags'])

assert(user.stories.first.name, 'A new name', 'name of story does not match')
assert(user.stories.first.description, 'fizzle', 'description of story does not match')
assert(user.stories.first.tags, ['love', 'me', 'some', 'tags'], 'tags of story does not match')

p 'Done Update Story'

# Create items
p 'Create Items'

assert(user.stories.first.items.create(type: 'embed', sub_type: 'dnz', content: {record_id: 123}, meta: {}), true, 'dnz embed item failed to create')
assert(user.stories.first.items.create(type: 'text', sub_type: 'heading', content: {value: 'Heading'}, meta: {size: 1}), true, 'heading item failed to create')

assert(user.stories.first.items.first.content[:record_id], 123, 'record_id does not match')
assert(user.stories.first.items.last.content[:value], 'Heading', 'heading value does not match')
assert(user.stories.first.items.count, 2, 'two items were not created')

p 'Done Create Items'

# Update item
p 'Update Item'

user.stories.first.items.first.update_attributes(content: {record_id: 456})

assert(user.stories.first.items.first.content, {record_id: 456}, 'record_id does not match')

p 'Done Update Item'

# Move item
p 'Move Item'

id = user.stories.first.items.first.id
user.stories.first.items.move_item(id, 2)

assert(user.stories.first.items.last.id, id, 'block did not get moved')

p 'Done Move Item'

# Delete item
p 'Delete Item'

user.stories.first.items.first.destroy

p 'Done Delete Item'

# Force refetch of stories
p 'Force refetch'

start = Time.now
user.stories.fetch(force: true)
end_time = Time.now

if ((start - end_time) * 1000) > 100
  p 'did not refetch'
end
# Have to refetch to check if item is deleted, so I put it here
assert(user.stories.first.items.count, 1, 'item was not deleted')

p 'Done Force refetch'

# Delete story
p 'Delete Story'

user.stories.first.destroy
user.stories.fetch(force: true)

assert(user.stories.count, 0, 'story was not deleted')

p 'Done Delete Story'
