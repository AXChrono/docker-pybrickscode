# Arguments
ARG NODE_TAG=18.15.0
ARG PYBRICKSCODE_TAG=v2.3.0-beta.1

# Build stage
FROM node:${NODE_TAG} AS build-stage
ARG PYBRICKSCODE_TAG
WORKDIR /app
RUN git clone https://github.com/pybricks/pybricks-code.git -b "${PYBRICKSCODE_TAG}" /app
RUN cd /app
RUN yarn install
RUN yarn build

# Production stage
FROM nginx:stable-alpine-slim
COPY --from=build-stage /app/build /usr/share/nginx/html
