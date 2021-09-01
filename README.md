# Gospec
Gospec is a concurrent test runner for RSpec built in Golang that closely \
follows the interface for RSpec with additional database tools to create
multiple databases in Rails Applications

## to install Gospec

1) install golang if it is not already installed \
https://golang.org/doc/install

2) install Gospec and build as an executable \
   go install https://github.com/leejroberts/gospec


## To set up your Rails app to work with Gospec (if using Rails)
in your database.yaml file
append the following to the end of the datebase name: `<%= ENV["DATABASE_NUMBER"] %>` 

For example
```yaml
test:
  database: my_cool_app_test<%= ENV["DATABASE_NUMBER"] %>
  // various other configurations
```

Once the above is complete and Gospec has been installed run

`gospec create`

this will take a some time, but will create 10 test databases that are exclusively used by Gospec \
for concurrent test runs

## To Use Gospec
To run a file
`gospec /path/to/spec/file/to/run_spec.rb`
To run a directory
`gospec /page/to/spec/directory/to/run`
To run multiple files and directories
`gospec /path/to/spec/file/to/run_spec.rb /page/to/spec/directory/to/run`

## Notes on current limitations
The nice progress rocket from Rspec is not currently present \
Pattern matching is not present at this time only file paths and directories \
Fail fast is not present at this time. \
Running a "blank" call to gospec does not trigger the entire spec suite to run but can easily be added
As I'm the only user, and I don't desire that functionality 
