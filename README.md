# TopList Application

A dynamic top list application built with Java Spring Boot backend and React frontend, featuring drag-and-drop functionality, voting system, and beautiful UI.

## Features

### Backend (Spring Boot)
- RESTful API for CRUD operations
- JPA/Hibernate for data persistence
- H2 in-memory database (development) / PostgreSQL (production)
- Category-based organization
- Voting system
- Ranking management

### Frontend (React)
- Modern, responsive UI with styled-components
- Drag-and-drop reordering with react-beautiful-dnd
- Smooth animations with framer-motion
- Category browsing and filtering
- Real-time voting
- Create and edit items

### Docker Support
- Multi-stage Dockerfile for production
- Docker Compose for development
- Nginx reverse proxy
- PostgreSQL database

## Quick Start

### Option 1: Single Container (Production)
```bash
# Build and run the complete application
docker build -t toplist-app .
docker run -p 80:80 -p 8080:8080 toplist-app
```

Access the application at http://localhost

### Option 2: Docker Compose (Development)
```bash
# Start all services (database, backend, frontend)
docker-compose up --build
```

- Frontend: http://localhost:3000
- Backend API: http://localhost:8080/api
- Database: PostgreSQL on port 5432

### Option 3: Local Development

#### Backend
```bash
# Run Spring Boot application
./mvnw spring-boot:run
```

#### Frontend
```bash
cd frontend
npm install
npm start
```

## API Endpoints

### Top List Items
- `GET /api/toplist` - Get all items
- `GET /api/toplist/{id}` - Get item by ID
- `GET /api/toplist/category/{category}` - Get items by category (ordered by rank)
- `GET /api/toplist/category/{category}/by-votes` - Get items by category (ordered by votes)
- `GET /api/toplist/categories` - Get all categories
- `GET /api/toplist/top-voted` - Get top voted items
- `POST /api/toplist` - Create new item
- `PUT /api/toplist/{id}` - Update item
- `POST /api/toplist/{id}/vote` - Vote for item
- `DELETE /api/toplist/{id}` - Delete item
- `PUT /api/toplist/category/{category}/reorder` - Update item ranks

## Technology Stack

### Backend
- Java 17
- Spring Boot 3.2.0
- Spring Data JPA
- H2 Database (development)
- PostgreSQL (production)
- Maven

### Frontend
- React 18
- React Router DOM
- Styled Components
- Framer Motion
- React Beautiful DnD
- React Icons
- Axios

### DevOps
- Docker & Docker Compose
- Nginx
- Multi-stage builds

## Project Structure

```
toplist-app/
├── src/main/java/com/toplist/          # Spring Boot backend
│   ├── controller/                     # REST controllers
│   ├── model/                         # JPA entities
│   ├── repository/                    # Data repositories
│   └── service/                       # Business logic
├── src/main/resources/                # Configuration files
├── frontend/                          # React frontend
│   ├── src/
│   │   ├── components/               # Reusable components
│   │   ├── pages/                    # Page components
│   │   └── services/                 # API services
│   └── public/                       # Static assets
├── Dockerfile                         # Production build
├── Dockerfile.backend                 # Backend-only build
├── docker-compose.yml                 # Development setup
└── nginx.conf                        # Nginx configuration
```

## Sample Data

The application comes with sample data including:
- **Movies**: The Shawshank Redemption, The Godfather, The Dark Knight, etc.
- **Books**: To Kill a Mockingbird, 1984, Pride and Prejudice, etc.
- **Music**: The Beatles, Led Zeppelin, Pink Floyd, etc.

## Development

### Adding New Categories
1. Update the categories array in `CreateItem.js` and `EditItem.js`
2. Add sample data in `data.sql` if needed

### Customizing Styles
- Global styles: `frontend/src/index.css`
- Component styles: Using styled-components in each component

### Database Configuration
- Development: H2 in-memory database
- Production: PostgreSQL (configure in `application-docker.yml`)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
