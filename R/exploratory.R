

library(fiery)
library(routr)
library(dplyr)

app <- Fire$new()
# When the app starts, we'll load the model we saved. Instead of
# polluting our namespace we'll use the internal data store

app$on('start', function(server, ...) {
  server$set_data('dataset', readr::read_file('db.json') )
  message('Dataset loaded')
})

# Just for show off, we'll make it so that the model is atomatically
# passed on to the request handlers

app$on('before-request', function(server, ...) {
  list(dataset = server$get_data('dataset'))
})

# Now comes the biggest deviation. We'll use routr to define our request
# logic, as this is much nicer
router <- RouteStack$new()
route <- Route$new()
router$add_route(route, 'main')

# We start with a catch-all route that provides a welcoming html page
route$add_handler('get', '*', function(request, response, keys, arg_list ,...) {
  response$status <- 200L
  response$body <- "{}"
  response$format(json = reqres::format_json())
  TRUE
})

#
# Then on to the /posts route
route$add_handler('get', '/posts', function(request, response, keys, arg_list, ...) {
  response$status <- 200L
  response$body <- arg_list$dataset %>%
                        jsonlite::fromJSON() %>%
                        magrittr::extract2("posts")
  response$format(json = reqres::format_json())
  TRUE
})

# Then on to the /posts/:id route
route$add_handler('get', '/posts/:id', function(request, response, keys, arg_list, ...) {
  response$status <- 200L
  response$body <- arg_list$dataset %>%
    jsonlite::fromJSON() %>%
    magrittr::extract2("posts") %>%
    dplyr::filter(id == keys$id)

  response$format(json = reqres::format_json())
  TRUE
})
#
# route$add_handler('get', '/predict', function(request, response, keys, arg_list, ...) {
#   response$body <- predict(
#     arg_list$model,
#     data.frame(x=as.numeric(request$query$val)),
#     se.fit = TRUE
#   )
#   response$status <- 200L
#   response$format(json = reqres::format_json())
#   TRUE
# })



# Finally we attach the router to the fiery server
app$attach(router)

app$ignite(block = FALSE)






