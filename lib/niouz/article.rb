module Niouz
  # Represents a news article stored as a simple text file in RFC822
  # format. Only the minimum information is kept in memory by instances
  # of this class:
  # * the message-id (+Message-ID+ header)
  # * the names of the newsgroups it is posted to (+Newsgroups+ header)
  # * the date it was posted (+Date+ header)
  # * overview data, generated on creation (see OVERVIEW_FMT)
  #
  # The rest (full header and body) are re-read from the file
  # each time it is requested.
  #
  # None of the methods in this class ever modify the content
  # of the file storing the article or the state of the instances
  # once created. Thread-safe.
  class Article
    # Creates a new Article from the content of file +fname+.
    def initialize(fname)
      @file = fname
      headers = File.open(fname) { |file| Niouz.parse_rfc822_header(file) }
      @mid = headers['Message-ID']
      @newsgroups = headers['Newsgroups'].split(/\s*,\s*/)
      @date = Niouz.parse_date(headers['Date'])
      # +Bytes+ and +Lines+ headers are required by the default
      # overview format, but they are not generated by all clients.
      # Only used for overview generation.
      headers['Bytes'] ||= File.size(fname).to_s
      headers['Lines'] ||= File.readlines(fname).length.to_s
      @overview = OVERVIEW_FMT.collect do |h|
        headers[h] ? headers[h].gsub(/(\r\n|\n\r|\n|\t)/, ' ') : nil
      end.join("\t")
    end

    # The message identifer.
    attr_reader :mid

    # The list of newsgroups (names) this article is in.
    attr_reader :newsgroups

    # Overview of this article (see OVERVIEW_FMT).
    attr_reader :overview

    # Tests whether this Article already existed at the given time.
    def existed_at?(aTime)
      return @date >= aTime
    end

    # Returns the head of the article, i.e. the content of the
    # associated file up to the first empty line.
    def head
      header = ''
      File.open(@file).each_line do |line|
        break if line.chomp.empty?
        header << line
      end
      return header
    end

    # Returns the body of the article, i.e. the content of the
    # associated file starting from the first empty line.
    def body
      lines = ''
      in_head = true
      File.open(@file).each_line do |line|
        in_head = false if in_head and line.chomp.empty?
        lines << line unless in_head
      end
      return lines
    end

    # Returns the full content of the article, head and body. This is
    # simply the verbatim content of the associated file.
    def content
      return IO.read(@file)
    end

    def matches_groups?(groups_specs) # TODO
      # See description of NEWNEWS command in RFC 977.
      return true
    end
  end
end
