FROM public.ecr.aws/lambda/ruby:2.7 AS build_image

# Uncomment this as a cache buster
#RUN echo date

# If you supplied buildArgs to the ecr image you can access them here using ARG & ENV
#ARG BUNDLE_GEM__FURY__IO
#ENV BUNDLE_GEM__FURY__IO=${BUNDLE_GEM__FURY__IO}

# First we install some stuff that we need for gems that have to compile native extensions
#RUN yum groupinstall "Development Tools" -y
#RUN yum install -y amazon-linux-extras
#RUN amazon-linux-extras enable postgresql11
#RUN yum install -y postgresql-devel

# Now we copy the Gemfile and Gemfile.lock into the build image so we can install our gems
COPY Gemfile Gemfile.lock .

# Set a few bundle configuration options
RUN bundle lock --add-platform x86_64-linux
#RUN bundle config --local deployment true
#RUN bundle config --local plugins false
#RUN bundle config --local frozen true
#RUN bundle config --local without 'development test'
RUN bundle config --local path './vendor/bundle'

# Now install our gems
RUN bundle install --quiet --jobs 4

# Now we start a second stage in the build that is a clean image without build tools
FROM public.ecr.aws/lambda/ruby:2.7 AS deploy_image

#ENV RAILS_ENV=production
#ENV RACK_ENV=production

# Install node so that asset related gems have a JS runtime.
# We ship the node executeable to production to make it easier to get an app deployed.
# TODO: Document steps that could be taken to remove this dependency.
#RUN curl --silent --location https://rpm.nodesource.com/setup_14.x | bash -
#RUN yum install -y nodejs

# Then copy some postgres related files
#COPY --from=build_image  /usr/lib64/libpq.so.5 /usr/lib64/
#COPY --from=build_image  /usr/lib64/libldap_r-2.4.so.2 /usr/lib64/
#COPY --from=build_image  /usr/lib64/liblber-2.4.so.2 /usr/lib64/
#COPY --from=build_image  /usr/lib64/libsasl2.so.3 /usr/lib64/
#COPY --from=build_image  /usr/lib64/libssl3.so /usr/lib64/
#COPY --from=build_image  /usr/lib64/libsmime3.so /usr/lib64/
#COPY --from=build_image  /usr/lib64/libnss3.so /usr/lib64/


# Next we copy the app from our local directory and we copy
# the bundled gems from the build image.
# We do this after copying dependencies becuase the app will
# change more frequently, and we can used caching up to here.

COPY --from=build_image /var/task .
COPY . .

# And finally we have the CMD for the deployed container
# You can overwrite command in `serverless.yml` template
CMD [ "app.LambdaFunction::Handler.process" ]

