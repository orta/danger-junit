# danger-junit

A description of danger-junit.

## Installation

    $ gem install danger-junit

## Usage



### junit

Report, or inspect any JUnit XML formatted test suite report.

Testing frameworks have standardized on the JUnit XML format for
reporting results, this means that projects using Rspec, Jasmine, Mocha,
XCTest and more - can all use the same Danger error reporting. Perfect.

You can see some examples on [this page from Circle CI](https://circleci.com/docs/test-metadata/)
about how you can add JUnit XML output for your testing projects.

<blockquote>Parse the XML file, and let the plugin do your reporting
  <pre>
junit.parse "/path/to/output.xml"
junit.report</pre>
</blockquote>

<blockquote>Let the plugin parse the XML file, and report yourself
  <pre>
junit.parse "/path/to/output.xml"
fail("Tests failed") unless junit.fails.empty?</pre>
</blockquote>

<blockquote>Warn on a report about skipped tests
  <pre>
junit.parse "/path/to/output.xml"
junit.show_skipped_tests = true
junit.report</pre>
</blockquote>

<blockquote>Only show specific parts of your results
  <pre>
junit.parse "/path/to/output.xml"
junit.headers = [:name, :file]
junit.report</pre>
</blockquote>

<blockquote>Only show specific parts of your results
  <pre>
junit.parse "/path/to/output.xml"
all_test = junit.tests.map(&:attributes)
slowest_test = sort_by { |attributes| attributes[:time].to_f }.last
message "#{slowest_test[:time]} took #{slowest_test[:time]} seconds"</pre>
</blockquote>



#### Attributes
<tr>
`tests` - All the tests for introspection
<tr>
`passes` - An array of XML elements that represent passed tests.
<tr>
`failures` - An array of XML elements that represent failed tests.
<tr>
`errors` - An array of XML elements that represent passed tests.
<tr>
`skipped` - An array of XML elements that represent skipped tests.
<tr>
`show_skipped_tests` - An attribute to make the plugin show a warning on skipped tests.
<tr>
`headers` - An array of symbols that become the columns of your tests,
if `nil`, the default, it will be all of the attribues.



#### Methods

`parse` - Parses an XML file, which fills all the attributes
will `raise` for errors

`report` - Causes a build fail if there are test failures,
and outputs a markdown table of the results.


## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
