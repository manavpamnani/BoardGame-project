# Use an official OpenJDK image as the base
FROM openjdk:17-jdk-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the built jar file to the container (you must build it first with mvn package)
COPY target/*.jar app.jar

# Expose the port your Spring Boot app runs on
EXPOSE 8080

# Command to run the Spring Boot app
ENTRYPOINT ["java", "-jar", "app.jar"]
