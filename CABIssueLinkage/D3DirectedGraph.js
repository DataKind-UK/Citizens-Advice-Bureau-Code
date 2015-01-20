require(["//cdnjs.cloudflare.com/ajax/libs/d3/3.4.1/d3.min.js", "widgets/js/manager"], function(d3, WidgetManager){
    var D3DirectedGraph = IPython.DOMWidgetView.extend({
        render: function(){
            this.guid = 'D3DirectedGraph' + IPython.utils.uuid();
            this.setElement($('<div />', {id: this.guid}));
                        
            // Wait for element to be added to the DOM
            var that = this;
            setTimeout(function() {
                that.update();
            }, 0);
        },

        update: function(){
            var height = this.model.get('height');
            var width = this.model.get('width');
            var distance = this.model.get('distance');
            var charge = this.model.get('charge');
            var nodes = this.model.get('nodes');
            var links = this.model.get('links');
            var max_node_size = this.model.get('max_node_size');
            var min_node_size = this.model.get('min_node_size');
            var node_color = this.model.get('node_color');
            var node_font = this.model.get('node_font');
            var node_highlight_color = this.model.get('node_highlight_color');
            var node_highlight_scale = this.model.get('node_highlight_scale');
            var link_color = this.model.get('link_color');
            var max_link_width = this.model.get('max_link_width');
            var min_link_width = this.model.get('min_link_width');
            var tooltip_color = this.model.get('tooltip_color');
            var tooltip_font = this.model.get('tooltip_font');

            var max_node_count = Math.max.apply(null,nodes.map(function(d) {return d['count'];}));
            var min_node_count = Math.min.apply(null,nodes.map(function(d) {return d['count'];}));
            var calc_node_size = function(d) {
                var count = nodes[d.index]['count'];
                var size = (count-min_node_count)*(max_node_size-min_node_size)/(max_node_count-min_node_count)+min_node_size;
                return size;}

            var max_link_weight = Math.max.apply(null,links.map(function(d) {return d['weight'];}));
            var min_link_weight = Math.min.apply(null,links.map(function(d) {return d['weight'];}));
            var calc_link_width = function(d) {
                var weight = d.weight;
                var width = (weight-min_link_weight)*(max_link_width-min_link_width)/(max_link_weight-min_link_weight)+min_link_width;
                return ""+width+"px";}

            var force = d3.layout.force()
                .nodes(nodes)
                .links(links)
                .size([width, height])
                .linkDistance(distance)
                .charge(-charge)
                .on("tick", tick)
                .start();

            var svg = d3.select("#" + this.guid).append("svg")
                .attr("width", width)
                .attr("height", height);

            // build the arrow.
            svg.append("svg:defs").selectAll("marker")
                .data(["end"])      // Different link/path types can be defined here
                .enter().append("svg:marker")    // This section adds in the arrows
                .attr("id", String)
                .attr("viewBox", "0 -5 10 10")
                .attr("refX", 10)
                .attr("refY", 0)
                .attr("markerWidth", 6)
                .attr("markerHeight", 6)
                .attr("orient", "auto")
                .append("svg:path")
                .attr("d", "M0,-5L10,0L0,5");

            var link = svg.selectAll("path")
                .data(force.links())
                .enter().append("path")
                .attr("class", "link")
                .style("stroke",link_color)
                .style("stroke-width",calc_link_width)
                //.style("opacity",calc_link_opacity)
                .attr("marker-end", "url(#end)");


            var node = svg.selectAll(".node")
                .data(force.nodes())
                .enter().append("g")
                .attr("class", "node")
                .on("mouseover", mouseover)
                .on("mouseout", mouseout)
                .call(force.drag);

            node.append("circle")
                .style("fill", node_color)
                .style("stroke",node_color)
                .style("stroke-width","1.5px")
                .attr("r", calc_node_size);

            node.append("text")
                .attr("x", 12)
                .attr("dy", ".35em")
                .text(function(d) { return d.id; })
                .style("font", node_font)
                .style("pointer-events", "none");

            var div = d3.select("body").append("div")   
                .attr("class", "tooltip")               
                .style("opacity", 0)
                .style("position", "absolute")           
                .style("text-align", "center")           
                .style("padding", "8px")             
                .style("font", tooltip_font)       
                .style("background", tooltip_color)   
                .style("border", "0px")      
                .style("border-radius", "8px")           
                .style("pointer-events", "none");  

            function tick() {
                link.attr("d", linkArc);
                node.attr("transform", transform);
            };

            function linkArc(d) {
                var sourceX = d.source.x;
                var sourceY = d.source.y;
                var targetX = d.target.x;
                var targetY = d.target.y;

                var theta = Math.atan((targetX - sourceX) / (targetY - sourceY));
                var phi = Math.atan((targetY - sourceY) / (targetX - sourceX));

                var sinTheta = calc_node_size(d.source) * Math.sin(theta);
                var cosTheta = calc_node_size(d.source) * Math.cos(theta);
                var sinPhi = calc_node_size(d.target) * Math.sin(phi);
                var cosPhi = calc_node_size(d.target) * Math.cos(phi);

                // Set the position of the link's end point at the source node
                // such that it is on the edge closest to the target node
                if (d.target.y > d.source.y) {
                    sourceX = sourceX + sinTheta;
                    sourceY = sourceY + cosTheta;
                }
                else {
                    sourceX = sourceX - sinTheta;
                    sourceY = sourceY - cosTheta;
                }

                // Set the position of the link's end point at the target node
                // such that it is on the edge closest to the source node
                if (d.source.x > d.target.x) {
                    targetX = targetX + cosPhi;
                    targetY = targetY + sinPhi;    
                }
                else {
                    targetX = targetX - cosPhi;
                    targetY = targetY - sinPhi;   
                }

                return "M" + sourceX + "," + sourceY + "L" + targetX + "," + targetY;
            }

            function transform(d) {
                return "translate(" + d.x + "," + d.y + ")";
            }


            function mouseover(d) {
                d3.select(this).select("circle").transition()
                    .duration(250)
                    .attr("r", calc_node_size(d)*node_highlight_scale)
                    .style("fill", node_highlight_color)
                    .style("stroke",node_highlight_color);

                div.transition()        
                    .duration(750)      
                    .style("opacity", 0.9);      

                div.html("<SPAN>"+d.id+"<br>"+nodes[d.index]['count']+"</SPAN>")
                    .style("left", (d3.event.pageX) + "px")     
                    .style("top", (d3.event.pageY - 28) + "px"); 
            }

            function mouseout() {
                div.transition()        
                    .duration(250)      
                    .style("opacity", 0); 

                d3.select(this).select("circle").transition()
                    .duration(750)
                    .attr("r", calc_node_size)
                    .style("fill", node_color)
                    .style("stroke",node_color);
            }
            return D3DirectedGraph.__super__.update.apply(this);
        }		

    });

    // Register the D3DirectedGraph with the widget manager.
    WidgetManager.register_widget_view('D3DirectedGraph', D3DirectedGraph);
});
