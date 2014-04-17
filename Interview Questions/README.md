Solutions to Interview Coding Questions
===========================

This project consists of a collection of solutions I wrote to sample interview questions.  The majority of the questions came from [careercup.com](http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions).  The following files contain several solutions I wrote to an interview question from a recent interview:
+ ```human_readable_int_a.rb```
+ ```human_readable_int_b.rb```
+ ```human_readable_int_c.rb```
+ ```question_009.rb```
The question was posed in the following manner:
> Devise a function that takes an input 'n' (integer) and returns a string that is the
> decimal representation of the number grouped by commas after every 3 digits. You can't
> solve the task using a built-in formatting function that can accomplish the whole
> task on its own.
>
> Assume: 0 <= n < 1000000000
>
> 1 -> "1"
> 10 -> "10"
> 100 -> "100"
> 1000 -> "1,000"
> 10000 -> "10,000"
> 100000 -> "100,000"
> 1000000 -> "1,000,000"
> 35235235 -> "35,235,235"