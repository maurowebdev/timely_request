# Employee Time-Off Tracking System

A Rails 8 application for managing employee time-off requests with role-based approval workflows.

## Features

- **Employee Management**: User registration, authentication, and role-based access
- **Time-Off Requests**: Submit and track vacation, sick leave, and personal time requests
- **Approval Workflow**: Managers approve/deny requests for direct reports
- **PTO Balance System**: Track accrued and used time-off with automated monthly accrual
- **API & Frontend**: RESTful JSON API with modern HTML interface using Stimulus

## Setup Instructions

### Prerequisites
- Ruby 3.4.1
- PostgreSQL
- Node.js (for asset compilation)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   npm install
   ```

3. Setup database:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. Start the server:
   ```bash
   rails server
   ```

### Test Users
After seeding, you can login with:
- **Admin**: admin@example.com / password123
- **Manager**: manager@example.com / password123
- **Employee**: mauricio.barros@example.com / password123

## API Documentation
See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete API reference.

## Testing
```bash
bundle exec rspec
```

## AI-Assisted Development

This project leveraged AI tools (Cursor, Claude) for:

### Most Useful AI Assistance:
- **Test Generation**: Generated comprehensive RSpec test suites for models, controllers, and services
- **Boilerplate Code**: Created migrations, models, and basic CRUD controllers
- **User Experience**: Stimulus controllers for dynamic form handling
- **Debugging**: Identified and fixed test pollution issues and deprecation warnings

### Manual Focus Areas:
- **Business Logic**: PTO balance calculations, overlapping request detection, PTO request approval, PTO Accrual calculations, Notifications, etc
- **Architecture**: Service objects for approval workflows, policy-based authorization

### Trade-offs Due to Time Constraints:
- Simplified email notifications (basic ActiveJob implementation)
- Basic audit trail (could be enhanced with more detailed logging)
- Limited time-off type customization (basic business rules implemented)
- No Holiday Calendar Integration

## Future Improvements
- JWT token-based authentication
- Enhanced reporting and analytics
- Mobile-responsive design improvements
- Advanced approval workflows (multi-level approvals)
- Integration with calendar systems
- Bulk operations for managers
