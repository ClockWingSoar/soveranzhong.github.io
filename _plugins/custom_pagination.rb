module Jekyll
    class Pagination < Generator
      safe true
  
      def generate(site)
        if site.config['pagination']['active']
          paginate(site)
        end
      end
  
      def paginate(site)
        all_posts = site.posts.docs.reverse
        paginate_size = site.config['pagination']['paginate'].to_i
        total_pages = (all_posts.size / paginate_size.to_f).ceil
  
        (1..total_pages).each do |current_page|
          pager = Pager.new(site, current_page, all_posts, total_pages, paginate_size)
          index_page = HomeIndexPage.new(site, current_page)
          index_page.pager = pager
          site.pages << index_page
        end
      end
    end
  
    class Pager
      attr_reader :current_page, :total_pages, :posts, :previous_page, :next_page
  
      def initialize(site, current_page, all_posts, total_pages, paginate_size)
        @current_page = current_page
        @total_pages = total_pages
        start = (current_page - 1) * paginate_size
        @posts = all_posts.slice(start, paginate_size)
        @previous_page = current_page > 1 ? current_page - 1 : nil
        @next_page = current_page < total_pages ? current_page + 1 : nil
      end
  
      def to_liquid
        {
          'current_page' => @current_page,
          'total_pages' => @total_pages,
          'posts' => @posts,
          'previous_page' => @previous_page,
          'next_page' => @next_page
        }
      end
    end
  
    class HomeIndexPage < Page
      def initialize(site, current_page)
        @site = site
        @base = site.source
        @dir = '/'
        @name = current_page == 1 ? 'blog.html' : "blog/#{current_page}.html"
        self.process(@name)
        self.read_yaml(File.join(@base, '_layouts'), 'blog.html')
        self.data['title'] = "Page #{current_page}" if current_page > 1
      end
    end
  end