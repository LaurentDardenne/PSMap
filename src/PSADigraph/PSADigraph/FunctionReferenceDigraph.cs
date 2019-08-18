using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation.Language;
using System.Reflection;
#if DEBUG
 using log4net;
 using log4net.Appender;
 using log4net.Config;
#endif

namespace PSADigraph
{
    //from PSScriptAnalyzer-master.1.18.0\Engine\Settings.cs
    public static class Constants
    {
        public const string DigraphEdgeAlreadyExists = "Edge from {0}  to {1} already exists.";
        public const string DigraphVertexAlreadyExists = "Vertex {0} already exists! Cannot add it to the digraph.";
        public const string DigraphVertexDoesNotExists = "Vertex {0} does not exist in the digraph.";
    }

    //from PSScriptAnalyzer-master.1.18.0\Engine\Helper.cs
    /// Class to represent a directed graph
    public class Digraph<T>
    {
        private List<List<int>> graph;
        private Dictionary<T, int> vertexIndexMap;

        /// <summary>
        /// Public constructor
        /// </summary>
        public Digraph()
        {
            graph = new List<List<int>>();
            vertexIndexMap = new Dictionary<T, int>();
        }

        /// <summary>
        /// Construct a directed graph that uses an EqualityComparer object for comparison with its vertices
        ///
        /// The class allows its client to use their choice of vertex type. To allow comparison for such a
        /// vertex type, client can pass their own EqualityComparer object
        /// </summary>
        /// <param name="equalityComparer"></param>
        public Digraph(IEqualityComparer<T> equalityComparer) : this()
        {
            if (equalityComparer == null)
            {
                throw new ArgumentNullException("equalityComparer");
            }

            vertexIndexMap = new Dictionary<T, int>(equalityComparer);
        }

        /// <summary>
        /// Return the number of vertices in the graph
        /// </summary>
        public int NumVertices
        {
            get { return graph.Count; }
        }

        /// <summary>
        /// Return an enumerator over the vertices in the graph
        /// </summary>
        public IEnumerable<T> GetVertices()
        {
            return vertexIndexMap.Keys;
        }

        /// <summary>
        /// Check if the given vertex is part of the graph.
        ///
        /// If the vertex is null, it will throw an ArgumentNullException.
        /// If the vertex is non-null but not present in the graph, it will throw an ArgumentOutOfRangeException
        /// </summary>
        /// <param name="vertex"></param>
        /// <returns>True if the graph contains the vertex, otherwise false</returns>
        public bool ContainsVertex(T vertex)
        {
            return vertexIndexMap.ContainsKey(vertex);
        }

        /// <summary>
        /// Get the neighbors of a given vertex
        ///
        /// If the vertex is null, it will throw an ArgumentNullException.
        /// If the vertex is non-null but not present in the graph, it will throw an ArgumentOutOfRangeException
        /// </summary>
        /// <param name="vertex"></param>
        /// <returns>An enumerator over the neighbors of the vertex</returns>
        public IEnumerable<T> GetNeighbors(T vertex)
        {
            ValidateVertexArgument(vertex);
            var idx = GetIndex(vertex);
            var idxVertexMap = vertexIndexMap.ToDictionary(x => x.Value, x => x.Key);
            foreach (var neighbor in graph[idx])
            {
                yield return idxVertexMap[neighbor];
            }
        }

        /// <summary>
        /// Gets the number of neighbors of the given vertex
        ///
        /// If the vertex is null, it will throw an ArgumentNullException.
        /// If the vertex is non-null but not present in the graph, it will throw an ArgumentOutOfRangeException
        /// </summary>
        /// <param name="vertex"></param>
        /// <returns></returns>
        public int GetOutDegree(T vertex)
        {
            ValidateVertexArgument(vertex);
            return graph[GetIndex(vertex)].Count;
        }

        /// <summary>
        /// Add a vertex to the graph
        ///
        /// If the vertex is null, it will throw an ArgumentNullException.
        /// If the vertex is non-null but already present in the graph, it will throw an ArgumentException
        /// </summary>
        /// <param name="vertex"></param>
        public void AddVertex(T vertex)
        {
            ValidateNotNull(vertex);
            if (GetIndex(vertex) != -1)
            {
                throw new ArgumentException(
                    String.Format(
                        Constants.DigraphVertexAlreadyExists,
                        vertex),
                    "vertex");
            }

            vertexIndexMap.Add(vertex, graph.Count);
            graph.Add(new List<int>());
        }

        /// <summary>
        /// Add an edge from one vertex to another
        ///
        /// If any input vertex is null, it will throw an ArgumentNullException
        /// If an edge is already present between the given vertices, it will throw an ArgumentException
        /// </summary>
        /// <param name="fromVertex"></param>
        /// <param name="toVertex"></param>
        public void AddEdge(T fromVertex, T toVertex)
        {
            ValidateVertexArgument(fromVertex);
            ValidateVertexArgument(toVertex);

            var toIdx = GetIndex(toVertex);
            var fromVertexList = graph[GetIndex(fromVertex)];
            if (fromVertexList.Contains(toIdx))
            {
                throw new ArgumentException(String.Format(
                    Constants.DigraphEdgeAlreadyExists,
                    fromVertex.ToString(),
                    toVertex.ToString()));
            }
            else
            {
                fromVertexList.Add(toIdx);
            }
        }

        /// <summary>
        /// Checks if a vertex is connected to another vertex within the graph
        /// </summary>
        /// <param name="vertex1"></param>
        /// <param name="vertex2"></param>
        /// <returns></returns>
        public bool IsConnected(T vertex1, T vertex2)
        {
            ValidateVertexArgument(vertex1);
            ValidateVertexArgument(vertex2);

            var visited = new bool[graph.Count];
            return IsConnected(GetIndex(vertex1), GetIndex(vertex2), ref visited);
        }

        /// <summary>
        /// Check if two vertices are connected
        /// </summary>
        /// <param name="fromIdx">Origin vertex</param>
        /// <param name="toIdx">Destination vertex</param>
        /// <param name="visited">A boolean array indicating whether a vertex has been visited or not</param>
        /// <returns>True if the vertices are conneted, otherwise false</returns>
        private bool IsConnected(int fromIdx, int toIdx, ref bool[] visited)
        {
            visited[fromIdx] = true;
            if (fromIdx == toIdx)
            {
                return true;
            }

            foreach (var vertexIdx in graph[fromIdx])
            {
                if (!visited[vertexIdx])
                {
                    if (IsConnected(vertexIdx, toIdx, ref visited))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        /// <summary>
        /// Throw an ArgumentNullException if vertex is null
        /// </summary>
        private void ValidateNotNull(T vertex)
        {
            if (vertex == null)
            {
                throw new ArgumentNullException("vertex");
            }
        }

        /// <summary>
        /// Throw an ArgumentOutOfRangeException if vertex is not present in the graph
        /// </summary>
        private void ValidateVertexPresence(T vertex)
        {
            if (GetIndex(vertex) == -1)
            {
                throw new ArgumentOutOfRangeException(
                    String.Format(
                        Constants.DigraphVertexDoesNotExists,
                        vertex.ToString()),
                    "vertex");
            }
        }

        /// <summary>
        /// Throw exception if vertex is null or not present in graph
        /// </summary>
        private void ValidateVertexArgument(T vertex)
        {
            ValidateNotNull(vertex);
            ValidateVertexPresence(vertex);
        }

        /// <summary>
        /// Get the index of the vertex in the graph array
        /// </summary>
        private int GetIndex(T vertex)
        {
            int idx;
            return vertexIndexMap.TryGetValue(vertex, out idx) ? idx : -1;
        }
    }

    //from PSScriptAnalyzer-master.1.18.0\Rules\UseShouldProcessCorrectly.cs
    /// <summary>
    /// Class to represent a vertex in a function call graph
    /// </summary>
    public class Vertex
    {
        public string Name { get { return name; } }
        public Ast Ast
        {
            get
            {
                return ast;
            }
            set
            {
                ast = value;
            }
        }

        public bool IsNestedFunctionDefinition { get { return isNestedFunctionDefinition; } }

        private string name;
        private Ast ast;
        private bool isNestedFunctionDefinition;

        public Vertex()
        {
            name = String.Empty;
        }

        public Vertex(string name, Ast ast)
        {
            if (name == null)
            {
                throw new ArgumentNullException("name");
            }
            this.name = name;
            this.ast = ast;
        }

        public Vertex(String name, Ast ast, bool isNestedFunctionDefinition)
            : this(name, ast)
        {
            this.isNestedFunctionDefinition = isNestedFunctionDefinition;
        }

        /// <summary>
        /// Returns string representation of a Vertex instance
        /// </summary>
        public override string ToString()
        {
            return name;
        }

        /// <summary>
        /// Compares two instances of Vertex class to check for equality
        /// </summary>
        public override bool Equals(Object other)
        {
            var otherVertex = other as Vertex;
            if (otherVertex == null)
            {
                return false;
            }

            if (name.Equals(otherVertex.name, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            return false;
        }

        /// <summary>
        /// Returns the Hash code of the given Vertex instance
        /// </summary>
        public override int GetHashCode()
        {
            return name.ToLowerInvariant().GetHashCode();
        }
    }

    //from PSScriptAnalyzer-master.1.18.0\Rules\UseShouldProcessCorrectly.cs

    /// <summary>
    /// Class to encapsulate a function call graph and related actions
    /// </summary>
    public class FunctionReferenceDigraph : AstVisitor
    {
#if DEBUG
        private static readonly log4net.ILog AppLogger = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
#endif
        private Digraph<Vertex> digraph;

        private Stack<Vertex> functionVisitStack;

        /// <summary>
        /// Construct a node name from all parent function names.
        /// for a F° 'GrandParent' that call F° 'Parent' that call F° 'Child' we build
        /// GrandParent.Parent.Child
        /// </summary>
        /// <param name="Stack"></param>
        /// <returns>The call stack object of the functions found bye the AST visitor</returns>
        private string BuildNameFromParents(Stack<Vertex> Stack)
        {
            //todo prendre la dernière partie du nom : Main.Parent.Child -> Child
            List<string> Names = Stack.Select(vertex => vertex.Name.Split('.').Last()).ToList();
            Names.Reverse();
            return String.Join(".", Names);
        }


        /// <summary>
        /// Checks if the AST being visited is in an instance FunctionDefinitionAst type
        /// </summary>
        private bool IsWithinFunctionDefinition()
        {
            return functionVisitStack.Count > 0;
        }

        /// <summary>
        /// Returns the function vertex whose children are being currently visited
        /// </summary>
        private Vertex GetCurrentFunctionContext()
        {
            return functionVisitStack.Peek();
        }

        /// <summary>
        /// Return the constructed digraph
        /// </summary>
        public Digraph<Vertex> GetDigraph()
        {
            return digraph;
        }

        /// <summary>
        /// Public constructor
        /// </summary>
        public FunctionReferenceDigraph()
        {
            digraph = new Digraph<Vertex>();
            functionVisitStack = new Stack<Vertex>();
#if DEBUG
            if (!log4net.LogManager.GetRepository().Configured)//ld
            {
                string assemblyFolder = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                FileInfo configFile = new FileInfo(Path.Combine(assemblyFolder, "log4net.config"));


                if (!configFile.Exists)
                {
                    throw new FileLoadException(String.Format("The configuration file {0} does not exist", configFile));
                }

                log4net.Config.XmlConfigurator.Configure(configFile);
            }
            AppLogger.Debug("Log FunctionReferenceDigraph");
#endif
        }

        /// <summary>
        /// Add a vertex to the graph
        /// </summary>
        public void AddVertex(Vertex vertex)
        {
#if DEBUG
            AppLogger.DebugFormat("Add Vertex Name {0} Type {1}", vertex.Name, vertex.Ast.GetType().FullName);
#endif
            bool containsVertex = false;

            // if the graph contains a vertex with name equal to that
            // of the input vertex, then update the vertex's ast if the
            // input vertex's ast is of FunctionDefinitionAst type
            foreach (Vertex v in digraph.GetVertices())
            {
                if (v.Equals(vertex))
                {
                    containsVertex = true;
#if DEBUG
                    if (vertex.Ast != null)
                        AppLogger.DebugFormat("Test vertices() Name {0} Type {1}", vertex.Name, vertex.Ast.GetType().FullName);
#endif
                    if (vertex.Ast != null
                        && vertex.Ast is FunctionDefinitionAst)
                    {
                        v.Ast = vertex.Ast;
#if DEBUG
                        AppLogger.DebugFormat("Update Vertex {0} functionAST", vertex.Name);
#endif
                    }
                    break;
                }
            }

            if (!containsVertex)
            {
#if DEBUG
                if (vertex.Ast != null)
                    AppLogger.DebugFormat("AddVertex Name {0} Type {1}", vertex.Name, vertex.Ast.GetType().FullName);
#endif
                digraph.AddVertex(vertex);
            }
        }

        /// <summary>
        /// Add an edge from a vertex to another vertex
        /// </summary>
        /// <param name="fromV">start of the edge</param>
        /// <param name="toV">end of the edge</param>
        public void AddEdge(Vertex fromV, Vertex toV)
        {
#if DEBUG
            AppLogger.DebugFormat("Add edge");
#endif
            if (!digraph.GetNeighbors(fromV).Contains(toV))
            {
#if DEBUG
            AppLogger.DebugFormat("Add edge from {0} to {1}",fromV.Name,toV.Name);
#endif                
                digraph.AddEdge(fromV, toV);
            }
        }

        /// <summary>
        /// Add a function to the graph; create a function context; and visit the function body
        /// </summary>
        public override AstVisitAction VisitFunctionDefinition(FunctionDefinitionAst ast)
        {
#if DEBUG
            AppLogger.DebugFormat("Call VisitFunctionDefinition");
#endif
            String CurrentNodeName;
            if (ast == null)
            {
                return AstVisitAction.SkipChildren;
            }

            if (IsWithinFunctionDefinition())
            {
                CurrentNodeName = BuildNameFromParents(functionVisitStack) + "." + ast.Name;
#if DEBUG
                AppLogger.DebugFormat("Dans une fonction {0} -> {1}", ast.Name, CurrentNodeName);
#endif
            }
            else
            {
#if DEBUG
                CurrentNodeName = BuildNameFromParents(functionVisitStack) + "." + ast.Name;
                AppLogger.DebugFormat("Pas dans une fonction {0} -> {1}", ast.Name, CurrentNodeName);
#endif

                CurrentNodeName = ast.Name;
            }

            //CurrentNodeName = ast.Name;
            var functionVertex = new Vertex(CurrentNodeName, ast, IsWithinFunctionDefinition());
            functionVisitStack.Push(functionVertex);
            AddVertex(functionVertex);
            ast.Body.Visit(this);
            functionVisitStack.Pop();
            return AstVisitAction.SkipChildren;
        }

        /// <summary>
        /// Add a command to the graph and if within a function definition, add an edge from the calling function to the command
        /// </summary>
        public override AstVisitAction VisitCommand(CommandAst ast)
        {
            String CurrentNodeName;
#if DEBUG
            AppLogger.DebugFormat("Call VisitCommand");
#endif
            if (ast == null)
            {
                return AstVisitAction.SkipChildren;
            }

            var cmdName = ast.GetCommandName();
            if (cmdName == null)
            {
#if DEBUG
                AppLogger.DebugFormat("VisitCommand GetCommandName {0} null",ast.ToString());
#endif
                return AstVisitAction.Continue;
            }

            if (IsWithinFunctionDefinition())
            {
                CurrentNodeName = BuildNameFromParents(functionVisitStack) + "." + cmdName;
#if DEBUG
                AppLogger.DebugFormat("Dans une fonction {0} -> {1}", cmdName, CurrentNodeName);
#endif
            }
            else
            {
#if DEBUG
                CurrentNodeName = BuildNameFromParents(functionVisitStack) + "." + cmdName;
                AppLogger.DebugFormat("Pas dans une fonction {0} -> {1}", cmdName, CurrentNodeName);
#endif

                CurrentNodeName = cmdName;
            }
            var vertex = new Vertex(CurrentNodeName, ast);
            AddVertex(vertex);
            if (IsWithinFunctionDefinition())
            {
#if DEBUG
                AppLogger.DebugFormat("VisitCommand {0} IsWithinFunctionDefinition", CurrentNodeName);
#endif
                AddEdge(GetCurrentFunctionContext(), vertex);
            }

            return AstVisitAction.Continue;
        }

        /// <summary>
        /// Add a member to the graph and if within a function definition, add an edge from the function to the member.
        /// NOTE : Not needed for CodeMap
        /// </summary>
//        public override AstVisitAction VisitInvokeMemberExpression(InvokeMemberExpressionAst ast)
//        {
//            if (ast == null)
//            {
//                return AstVisitAction.SkipChildren;
//            }
//#if DEBUG
//            AppLogger.DebugFormat("VisitInvokeMemberExpression begin: ", ast.ToString());
//#endif
//            var expr = ast.Expression.Extent.Text;
//            var memberExprAst = ast.Member as StringConstantExpressionAst;
//            if (memberExprAst == null)
//            {
//#if DEBUG
//                AppLogger.DebugFormat("VisitInvokeMemberExpression {0} not StringConstantExpressionAst", ast.ToString());
//#endif
//                return AstVisitAction.Continue;
//            }

//            var member = memberExprAst.Value;
//            if (string.IsNullOrWhiteSpace(member))
//            {
//#if DEBUG
//                AppLogger.DebugFormat("VisitInvokeMemberExpression {0} memberExprAst isnull or empty", ast.ToString());
//#endif
//                return AstVisitAction.Continue;
//            }
//#if DEBUG
//            AppLogger.DebugFormat("VisitInvokeMemberExpression  member= {0} -> AddVertex", memberExprAst.ToString());
//#endif
//            // Suppose we find <Expression>.<Member>, we split it up and create
//            // and edge only to <Member>. Even though <Expression> is not
//            // necessarily a function, we do it because we are mainly interested in
//            // finding connection between a function and ShouldProcess and this approach
//            // prevents any unnecessary complexity.
//            //
//            // Note : Seems to find the presence of '$PSCmdlet.ShouldProcess' for PSSA rules.
//            var memberVertex = new Vertex(memberExprAst.Value, memberExprAst);
//            AddVertex(memberVertex);
//            if (IsWithinFunctionDefinition())
//            {
//#if DEBUG
//                AppLogger.DebugFormat("VisitInvokeMemberExpression  {0} IsWithinFunctionDefinition -> AddEdge", memberExprAst.Value);
//#endif
//                AddEdge(GetCurrentFunctionContext(), memberVertex);
//            }

//            return AstVisitAction.Continue;
//        }

        /// <summary>
        /// Return the vertices in the graph
        /// </summary>
        public IEnumerable<Vertex> GetVertices()
        {
            return digraph.GetVertices();
        }

        /// <summary>
        /// Check if two vertices are connected
        /// </summary>
        /// <param name="vertex">Origin vertxx</param>
        /// <param name="shouldVertex">Destination vertex</param>
        /// <returns></returns>
        public bool IsConnected(Vertex vertex, Vertex shouldVertex)
        {
            if (digraph.ContainsVertex(vertex)
                && digraph.ContainsVertex(shouldVertex))
            {
                return digraph.IsConnected(vertex, shouldVertex);
            }
            return false;
        }

        /// <summary>
        /// Get the number of edges out of the given vertex
        /// </summary>
        public int GetOutDegree(Vertex v)
        {
            return digraph.GetOutDegree(v);
        }

        public IEnumerable<Vertex> GetNeighbors(Vertex v)
        {
            return digraph.GetNeighbors(v);
        }
    }
}
