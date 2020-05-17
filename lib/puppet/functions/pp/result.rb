require 'stringio'

# Pretty print Bolt results
Puppet::Functions.create_function(:'pp::result') do
  dispatch :format_resultset do
    param 'ResultSet', :results
    return_type 'Undef'
  end

  dispatch :format_applyresult do
    param 'ApplyResult', :result
    return_type 'Undef'
  end

  dispatch :format_result do
    param 'Result', :result
    return_type 'Undef'
  end

  def format_resultset(results)
    results.results.each do |result|
      call_function('pp::result', result)
    end

    nil
  end

  def format_applyresult(result)
    output = StringIO.new

    output.puts("\t%<status>-9s %{name} %{uri}" %
                {name: result.target.name,
                 uri: result.target.uri,
                 status: "(#{result.status})"})

    # TODO: Would be great to interleave logs with resource statuses
    #       with adjustable levels: i.e. default to warning and above,
    #       add more detail along with unchanged resources if verbosity
    #       level is set high. Etc.
    result.report['resource_statuses'].each do |_, resource|
      status = if resource['failed'] || resource['failed_to_restart']
                 'failed'
               elsif resource['changed']
                 'changed'
               else
                 # TODO: Noop, skipped, and audited are also important.
                 'insync'
               end

      next unless ['failed', 'changed'].include?(status)

      output.puts("\t\t%<status>-9s %{name}" %
                  {status: "(#{status})",
                   name: resource['resource']})
    end

    output.puts("\t\t%{summary}" %
                {summary: result.metrics_message})

    output.close

    call_function('out::message', output.string)

    nil
  end

  def format_result(_result)
    # TODO: Currently a no-op.
    nil
  end
end
