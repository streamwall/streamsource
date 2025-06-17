# StreamSource Admin Interface Documentation

## Overview

The StreamSource admin interface is a modern web application built with Rails 8 and Hotwire, providing a rich, interactive experience for managing streams, users, and application settings without page refreshes.

## Technology Stack

- **Backend**: Rails 8.0.2 with session-based authentication
- **Frontend Framework**: Hotwire (Turbo + Stimulus)
- **CSS Framework**: Tailwind CSS 3.4
- **JavaScript Bundler**: ESBuild
- **Package Manager**: Yarn

## Features

### Stream Management
- **CRUD Operations**: Create, read, update, and delete streams
- **Real-time Search**: Filter streams as you type with debounced search
- **Advanced Filtering**: Filter by status, pin state, and search terms
- **Pin/Unpin**: Mark important streams with a single click
- **Pagination**: Efficient browsing with Pagy pagination
- **Modal Forms**: Edit streams in modal dialogs without page refresh

### User Management
- **User List**: View all users with their roles and stream counts
- **Role Management**: Promote/demote users between roles
- **User Creation**: Add new users with specified roles
- **User Editing**: Update user information

### Feature Flags
- **Flipper Integration**: Toggle features on/off in real-time
- **Group Management**: Enable features for specific user groups
- **Percentage Rollouts**: Gradually roll out features to user percentages

## Accessing the Admin Interface

### Login
1. Navigate to `http://localhost:3000/admin/login`
2. Enter admin credentials:
   - Email: `admin@example.com`
   - Password: `password123` (in development)
3. Click "Sign In"

### Navigation
The admin interface features a sidebar with the following sections:
- **Streams**: Main stream management interface
- **Users**: User management
- **Feature Flags**: Feature toggle management
- **Logout**: End admin session

## Architecture

### Controllers

#### `Admin::BaseController`
Base controller for all admin controllers providing:
- Session-based authentication
- Admin user authorization
- Maintenance mode checking
- Common layout and helpers

#### `Admin::StreamsController`
Handles all stream-related operations:
- Index with filtering and pagination
- Create/update with Turbo Stream responses
- Delete with confirmation
- Pin/unpin toggle functionality

#### `Admin::SessionsController`
Manages admin authentication:
- Login page rendering
- Authentication logic
- Session management
- Logout functionality

### Views Structure

```
app/views/
├── admin/
│   ├── streams/
│   │   ├── index.html.erb      # Main streams list
│   │   ├── new.html.erb        # New stream form
│   │   ├── edit.html.erb       # Edit stream form
│   │   ├── _stream.html.erb    # Stream row partial
│   │   └── _form.html.erb      # Shared form partial
│   ├── sessions/
│   │   └── new.html.erb        # Login page
│   └── shared/
│       ├── _flash.html.erb     # Flash messages
│       └── maintenance.html.erb # Maintenance mode page
└── layouts/
    ├── admin.html.erb           # Main admin layout
    └── admin_login.html.erb     # Login page layout
```

### JavaScript Controllers

#### `modal_controller.js`
Manages modal dialogs for forms:
- Opens/closes modals
- Handles ESC key and outside clicks
- Integrates with Turbo Frames

#### `search_controller.js`
Implements real-time search:
- Debounces input (300ms delay)
- Submits form via Turbo
- Maintains filter state

### Styling

The interface uses Tailwind CSS with a custom color scheme:
- **Primary**: Indigo (buttons, links)
- **Success**: Green (active status, success messages)
- **Danger**: Red (delete actions, error states)
- **Neutral**: Gray (backgrounds, borders)

## Real-time Features with Hotwire

### Turbo Frames
Used for partial page updates:
- `#modal` - Modal dialog container
- `#streams_list` - Streams table and pagination
- `#flash` - Flash message container

### Turbo Streams
Provides real-time updates after actions:
- Prepends new streams to the list
- Removes deleted streams
- Updates flash messages
- Closes modals after successful operations

### Stimulus Controllers
Enhance interactivity:
- **Modal Controller**: Manages modal lifecycle
- **Search Controller**: Handles search input debouncing

## Security

### Authentication
- Session-based authentication separate from API JWT
- Secure password storage with bcrypt
- CSRF protection on all forms
- Session timeout after inactivity

### Authorization
- Only users with `admin` role can access
- Checks performed in `BaseController`
- Redirects to login if unauthorized

## Development

### Adding New Admin Pages

1. **Create Controller**
```ruby
module Admin
  class YourController < BaseController
    def index
      @items = YourModel.all
    end
    
    # Other CRUD actions...
  end
end
```

2. **Add Routes**
```ruby
namespace :admin do
  resources :your_resources
end
```

3. **Create Views**
- Follow existing patterns in `app/views/admin/`
- Use Turbo Frames for dynamic updates
- Apply Tailwind classes for consistency

### Building Assets

```bash
# Build JavaScript
yarn build

# Build CSS
yarn build:css

# Watch mode for development
yarn build --watch
yarn build:css --watch
```

### Testing Admin Features

1. **Controller Tests**
```ruby
RSpec.describe Admin::StreamsController do
  let(:admin) { create(:user, :admin) }
  
  before { sign_in(admin) }
  
  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to be_successful
    end
  end
end
```

2. **System Tests**
```ruby
RSpec.describe "Admin Streams Management", type: :system do
  let(:admin) { create(:user, :admin) }
  
  before do
    login_as(admin)
    visit admin_streams_path
  end
  
  it "creates a new stream" do
    click_link "New Stream"
    fill_in "Name", with: "Test Stream"
    fill_in "URL", with: "https://example.com"
    click_button "Create Stream"
    
    expect(page).to have_content("Stream was successfully created")
    expect(page).to have_content("Test Stream")
  end
end
```

## Troubleshooting

### Common Issues

1. **Assets not loading**
   - Run `yarn build && yarn build:css`
   - Check that symlinks exist in `public/assets/`
   - Clear browser cache

2. **Turbo not working**
   - Ensure `data-turbo-frame` attributes are correct
   - Check browser console for JavaScript errors
   - Verify Stimulus controllers are registered

3. **Authentication issues**
   - Check session configuration in `application.rb`
   - Verify middleware stack includes session support
   - Ensure cookies are enabled in browser

### Debugging Tips

1. **Enable Turbo debugging**
```javascript
Turbo.session.drive = false // Disable Turbo temporarily
```

2. **Check Stimulus controllers**
```javascript
// In browser console
Stimulus.controllers
```

3. **Rails logs**
```bash
docker-compose logs -f web
tail -f log/development.log
```

## Best Practices

1. **Keep controllers thin**
   - Use scopes and filters in models
   - Extract complex logic to service objects

2. **Optimize queries**
   - Use `includes` to avoid N+1 queries
   - Implement proper pagination

3. **Maintain consistency**
   - Follow existing UI patterns
   - Use shared partials for common elements
   - Apply consistent Tailwind classes

4. **Enhance progressively**
   - Ensure basic functionality works without JavaScript
   - Add Stimulus enhancements on top
   - Test with JavaScript disabled

## Future Enhancements

### Planned Features
- Dashboard with analytics
- Bulk operations for streams
- Advanced user permissions
- Activity logging
- Export functionality

### Performance Optimizations
- Implement caching for frequently accessed data
- Add background jobs for heavy operations
- Optimize asset delivery with CDN
- Implement infinite scroll for large lists