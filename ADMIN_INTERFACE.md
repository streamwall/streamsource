# StreamSource Admin Interface Documentation

## Overview

The StreamSource admin interface is a modern web application built with Rails 8 and Hotwire, providing a rich, interactive experience for managing streamers, streams, annotations, users, and application settings without page refreshes. It includes real-time updates via ActionCable for collaborative administration.

## Technology Stack

- **Backend**: Rails 8.0.x with session-based authentication
- **Frontend Framework**: Hotwire (Turbo + Stimulus) with ActionCable
- **CSS Framework**: Tailwind CSS 3.4
- **JavaScript Bundler**: ESBuild
- **Package Manager**: Yarn
- **Real-time**: ActionCable WebSockets

## Features

### Streamer Management
- **CRUD Operations**: Create, read, update, and delete streamers
- **Platform Accounts**: Manage streamer accounts across different platforms
- **Associated Streams**: View and manage all streams for a streamer
- **Notes**: Add notes to streamers for tracking important information

### Stream Management
- **CRUD Operations**: Create, read, update, and delete streams
- **Real-time Search**: Filter streams as you type with debounced search
- **Advanced Filtering**: Filter by status, platform, streamer, city, state, and more
- **Pin/Unpin**: Mark important streams with a single click
- **Archive/Unarchive**: Archive old streams while keeping data
- **Stream Attributes**: Manage platform, orientation, kind, timestamps
- **Pagination**: Efficient browsing with Pagy pagination
- **Modal Forms**: Edit streams in modal dialogs without page refresh
- **Notes**: Add notes to streams for documentation

### Annotation Management
- **Incident Tracking**: Create and manage incident annotations
- **Priority Levels**: Set priorities (low, medium, high, critical)
- **Status Tracking**: Track status (pending, in_progress, resolved, closed)
- **Stream Association**: Link annotations to multiple streams
- **Timeline View**: View incidents in chronological order

### User Management
- **User List**: View all users with their roles and stream counts
- **Role Management**: Promote/demote users between roles
- **User Creation**: Add new users with specified roles
- **User Editing**: Update user information

### Notes System
- **Polymorphic Notes**: Add notes to streams or streamers
- **User Attribution**: Track who created each note
- **Rich Content**: Support for detailed documentation

### Feature Flags
- **Flipper Integration**: Toggle features on/off in real-time
- **Group Management**: Enable features for specific user groups
- **Percentage Rollouts**: Gradually roll out features to user percentages

## Accessing the Admin Interface

### Login
1. Navigate to `http://localhost:3000/admin/login`
2. Enter admin credentials:
   - Email: `admin@example.com`
   - Password: `Password123!` (in development)
3. Click "Sign In"

### Navigation
The admin interface features a sidebar with the following sections:
- **Streams**: Main stream management interface
- **Streamers**: Content creator management
- **Annotations**: Incident and event tracking
- **Users**: User management
- **Notes**: View all notes across the system
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
- Archive/unarchive functionality
- Platform and status filtering

#### `Admin::StreamersController`
Manages content creators:
- CRUD operations for streamers
- Platform account management
- Associated streams view
- Notes management

#### `Admin::AnnotationsController`
Handles incident tracking:
- Create and manage annotations
- Priority and status management
- Stream association
- Timeline visualization

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
│   ├── streamers/
│   │   ├── index.html.erb      # Streamers list
│   │   ├── show.html.erb       # Streamer details
│   │   ├── new.html.erb        # New streamer form
│   │   ├── edit.html.erb       # Edit streamer form
│   │   └── _form.html.erb      # Shared form partial
│   ├── annotations/
│   │   ├── index.html.erb      # Annotations list
│   │   ├── show.html.erb       # Annotation details
│   │   ├── new.html.erb        # New annotation form
│   │   ├── edit.html.erb       # Edit annotation form
│   │   └── _form.html.erb      # Shared form partial
│   ├── notes/
│   │   └── index.html.erb      # All notes view
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

#### `dropdown_controller.js`
Handles dropdown menus:
- Toggle visibility
- Click outside to close
- Keyboard navigation

#### `filters_controller.js`
Manages advanced filtering:
- Platform selection
- Status filtering
- Date range pickers

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
- `#streamers_list` - Streamers table and pagination
- `#annotations_list` - Annotations table and pagination
- `#flash` - Flash message container
- `#sidebar_counts` - Live count updates

### Turbo Streams
Provides real-time updates after actions:
- Prepends new streams/streamers/annotations to lists
- Removes deleted items
- Updates flash messages
- Closes modals after successful operations
- Live updates via ActionCable broadcasts

### ActionCable Channels
Real-time WebSocket channels:
- `AdminChannel` - General admin updates
- `StreamChannel` - Stream-specific updates
- `AnnotationChannel` - Annotation updates
- Automatic UI updates when other admins make changes

### Stimulus Controllers
Enhance interactivity:
- **Modal Controller**: Manages modal lifecycle
- **Search Controller**: Handles search input debouncing
- **Dropdown Controller**: Dropdown menu management
- **Filters Controller**: Advanced filtering interface
- **Confirm Controller**: Confirmation dialogs
- **Flash Controller**: Auto-dismiss flash messages

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
    before_action :set_item, only: [:show, :edit, :update, :destroy]

    def index
      @items = YourModel.includes(:associations)
                        .page(params[:page])
                        .per(25)
    end

    def new
      @item = YourModel.new
    end

    def create
      @item = YourModel.new(item_params)

      if @item.save
        redirect_to admin_items_path,
                    notice: 'Item was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_item
      @item = YourModel.find(params[:id])
    end

    def item_params
      params.require(:your_model).permit(:allowed, :attributes)
    end
  end
end
```

2. **Add Routes**
```ruby
namespace :admin do
  resources :your_resources do
    member do
      post :custom_action
    end
    collection do
      get :export
    end
  end
end
```

3. **Create Views**
- Follow existing patterns in `app/views/admin/`
- Use Turbo Frames for dynamic updates
- Apply Tailwind classes for consistency

### Building Assets

```bash
# Build JavaScript
docker compose exec web yarn build

# Build CSS
docker compose exec web yarn build:css

# Watch mode for development (using profiles)
docker compose --profile donotstart up js
docker compose --profile donotstart up css
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
docker compose logs -f web
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
- Dashboard with analytics and metrics
- Bulk operations for streams and annotations
- Advanced user permissions and roles
- Comprehensive activity logging
- Export functionality for all data types
- API for admin operations
- Mobile-responsive improvements
- Advanced search with Elasticsearch

### Performance Optimizations
- Implement caching for frequently accessed data
- Add background jobs for heavy operations
- Optimize asset delivery with CDN
- Implement infinite scroll for large lists