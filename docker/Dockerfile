FROM r-base:3.5.0

RUN apt-get update || apt-get update && apt-get install -y \
  libcurl4-openssl-dev \
  libssl-dev

# Despite the docs, Dirk's little.r does not seem to successfully read
# ~/.Rprofile but we need this set.  It might be easier to patch
# install2.r to just use Rscript, but this hack works for now.
COPY docker/littler.r /root/.littler.r

# Can't use --error here because (a) the drat was written by 3.3.x
# that does not write out PACKAGES.rds file and (b) install2.r throws
# on all warnings, not just the ones that signal installation failure.
RUN install2.r \
        base64enc \
        dockopt \
        drat \
        getPass \
        httr \
        jsonlite \
        montagu \
        openssl \
        prettyunits \
        progress \
        remotes \
        rdrop2 \
        stringi \
        vaultr

RUN Rscript -e 'remotes::install_github("vimc/montagu-r@i907")'

COPY . /pkg
RUN R CMD INSTALL /pkg && \
        cp /pkg/inst/montagu.import /usr/local/bin && \
        rm -rf /pkg

ENTRYPOINT ["montagu.import"]
