# Stage 1: Build Stage
FROM maven:3.8-openjdk-11 AS build

WORKDIR /app

# Install Git (Git is not included by default in Maven images)
RUN apt-get update && apt-get install git -y

# Set the working directory
WORKDIR /app

# Clone the Git repository
RUN git clone https://github.com/raja1928/java-onlinebookstore.git


# Build the application using Maven (adjust the target if needed)
WORKDIR /app/java-onlinebookstore

RUN mvn clean install

# Stage 2: Final Stage (Using Tomcat)
FROM tomcat:9-jdk17

# Set the working directory in the Tomcat container
WORKDIR /usr/local/tomcat/webapps
RUN cp -r ../webapps.dist/* ./

# Copy the WAR file from the build stage (adjust the WAR file name if needed)
COPY --from=build /app/java-onlinebookstore/target/onlinebookstore.war ./onlinebookstore.war

# Expose Tomcat's default HTTP port
EXPOSE 8080

# Start Tomcat (catalina.sh is the default entry point for Tomcat)
CMD ["catalina.sh", "run"]
