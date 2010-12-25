module Automan
  module Version
    class VersionNode
      attr_accessor :version #string
      attr_accessor :name #string
      attr_accessor :parent #VersionNode
      def to_s
        return "#{name} #{version}: #{path}"
      end
      def initialize(version_number, name)
        @version = version_number
        @name = name
      end
      def ver_eql(node)
        return false unless(node)
        return node.version.eql?(self.version)
      end
      def path
        return File.join(@parent.path, @name)
      end
      def need_update(server_node)
        raise NotImplementedError.new("#{self.class.name}#area是抽象方法")
      end
    end
    class FileNode < VersionNode
      def initialize(version_number, name, file_url)
        super(version_number, name)
        @url = file_url
      end
      attr_accessor :url
      def need_update(local_node)
        result = []
        unless local_node
          result << {:AddFile => self}
        else
          unless(ver_eql(local_node))
            result << {:UpdateFile => self}
          end
        end
        return result
      end
    end
    class FolderNode < VersionNode
      def initialize(version_number, name)
        super
        @sub_nodes = []
      end
      attr_reader :sub_nodes
      def add_nodes(nodes)
        Array(nodes).each { |n|
          n.parent = self
          @sub_nodes << n
        }
      end
      def find_same_name(node)
        @sub_nodes.each{|n|
          if(n.name == node.name)
            return n
          end
        }
        return nil
      end
      def need_update(local_node)
        result = []
        unless(local_node)#本地不存在
          result << {:AddDir=>File.join(self.path)}
          @sub_nodes.each { |n|
            result.concat(n.need_update(nil))
          }
        else
          unless(ver_eql(local_node))
            #开始找下面哪里不一样
            local_sub = local_node.sub_nodes

            @sub_nodes.each { |n|
              ln = local_node.find_same_name(n) #查找到本地的节点
              if(ln)
                #找到了本地的节点
                unless(ln.ver_eql(n))
                  result.concat(n.need_update(ln))
                end
              else
                #找不到本地的节点
                result.concat(n.need_update(nil))
              end
            }
          
            local_sub.each{|ln|
              sn = self.find_same_name(ln) #查找服务器的节点
              #找不到服务器上的节点
              unless(sn)
                result << {:Del=>File.join(self.path, ln.name)}
              end
            }
          end
        end
        return result
      end
    end
    class VersionRoot < FolderNode
      def initialize(version_number, name)
        super(version_number, name)
      end
      attr_accessor :project_name, :ref_project_name
      attr_reader :root_path
      
      def get_list(local_node, root_path)
        @root_path = root_path
        return need_update(local_node)
      end
      def path
        return @root_path
      end
    end
  end
end