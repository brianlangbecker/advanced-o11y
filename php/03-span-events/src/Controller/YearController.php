<?php

namespace App\Controller;

require __DIR__ . '/../../vendor/autoload.php';

use App\OpenTelemetry\HasTraceableTrait;
use App\OpenTelemetry\SdkBuilder;
use OpenTelemetry\API\Signals;
use OpenTelemetry\API\Trace\Propagation\TraceContextPropagator;
use OpenTelemetry\API\Trace\SpanInterface;
use OpenTelemetry\Contrib\Otlp\OtlpHttpTransportFactory;
use OpenTelemetry\Contrib\Otlp\OtlpUtil;
use OpenTelemetry\Contrib\Otlp\SpanExporter;
use OpenTelemetry\SDK\Common\Attribute\Attributes;
use OpenTelemetry\SDK\Common\Configuration\Configuration;
use OpenTelemetry\SDK\Common\Configuration\Variables;
use OpenTelemetry\SDK\Common\Time\ClockFactory;
use OpenTelemetry\SDK\Resource\ResourceInfo;
use OpenTelemetry\SDK\Sdk;
use OpenTelemetry\SDK\Trace\SpanProcessor\BatchSpanProcessor;
use OpenTelemetry\SDK\Trace\TracerProvider;
use OpenTelemetry\SemConv\ResourceAttributes;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\Response;


class YearController extends AbstractController
{
    use HasTraceableTrait;

    private TracerProvider $tracerProvider;

    private ?SpanInterface $span, $root, $scope = null;

    #[Route('/year', name: 'app_year')]
    public function index(): Response
    {
        $randomYear = $this->getRandomYear();

        //$this->instrumentedNormal();
        $this->instrumentEasier();

        $message = "Span events exercise updated. Go see your OpenTelemetry traces in Honeycomb!";
        return $this->createHtmlResponse($message);

    }

    // This the normal way without creating a helper function
    public function instrumentedNormal()
    {
        // Setup tracers, exporters, connection
        $headers = [];
        $headers = OtlpUtil::getHeaders(Signals::TRACE);

        // If using collector, it probably works better with 'application/json'. For Honeycomb it only worked with 'application/x-protobuf'/ C
        $transport = (new OtlpHttpTransportFactory())->create(Configuration::getString(Variables::OTEL_EXPORTER_OTLP_ENDPOINT), 'application/x-protobuf', $headers);
        $exporter = new SpanExporter($transport);

        $resource = ResourceInfo::create(Attributes::create([
            ResourceAttributes::SERVICE_NAMESPACE => 'Demo',
            ResourceAttributes::SERVICE_NAME => 'year-php',
        ]));

        $tracerProvider = new TracerProvider(
            spanProcessors: [new BatchSpanProcessor($exporter, ClockFactory::getDefault())],
            resource: $resource,
        );

        Sdk::builder()
            ->setTracerProvider($tracerProvider)
            ->setPropagator(TraceContextPropagator::getInstance())
            ->setAutoShutdown(true)
            ->buildAndRegisterGlobal();

        $tracer = $tracerProvider->getTracer('year-php');

        // Create root span
        $root = $span = $tracer->spanBuilder('root')->startSpan();
        $scope = $span->activate();

        for ($i = 0; $i < 3; $i++) {
            // Start another span
            $span = $tracer->spanBuilder('loop-' . $i)->startSpan();

            $span->setAttribute('year', $this->getRandomYear());

            // Add span events
            $span->addEvent('event ' . $i, [
                'event_id' => $i,
                'username' => 'otuser' . $i,
            ]);
            $span->addEvent('generated_session', [
                'id' => md5((string) microtime(true)),
            ]);

            $span->end();
        }

        // Let's play with span links
        //$span = $tracer->spanBuilder('Play with links')->setParent(false)->startSpan();

        //$spanContext = $span->getContext();
        //$span->end();

        // Associate it back
        //$span = $tracer->spanBuilder('span-with-link')
        //    ->addLink($spanContext)
        //    ->startSpan();

        //$span->end();
        $root->end();
        $scope->detach();
        $tracerProvider->shutdown();
        return;
    }

    // This is the way using helper functions, inspired by Daniel
    function instrumentEasier()
    {
        // Setup tracers, exporters, connection
        $builder = new SdkBuilder(); // This is a helper function
        $builder->build();

        // Create root span
        $root = $this->createSpan('root-easier');

        // Active it
        $scope = $root->activate();
        for ($i = 0; $i < 3; $i++) {
            // start a span, register some events, add span events
            $span = $this->createSpan('loop-' . $i);

            // Add custom attributes
            $span->setAttribute('year', $this->getRandomYear());

            // Add span events
            $span->addEvent('event ' . $i, [
                'event_id' => $i,
                'username' => 'otuser' . $i,
            ]);

            $span->addEvent('generated_session', [
                'id' => md5((string) microtime(true)),
            ]);

            $span->end();
        }
        // Let's play with span links
        //$span = $this->createSpan('Play with links', true);

        //$spanContext = $span->getContext();
        //$span->end();

        // Associate it back
        //$span = $this->createSpanWithLink('span-with-link', $spanContext);
        //$span->end();
        $scope->detach();
        $root->end();
        return;
    }

    function getRandomYear(): int
    {
        $currentYear = date("Y"); // Get the current year
        usleep(rand(0, 5000)); // Simulate a small delay
        $randomYear = rand(2015, $currentYear); // Get a random year between 2015 and current year
        return $randomYear;
    }

    private function createHtmlResponse(string $message): Response
    {
        // HTML content with styles
        $htmlContent = <<<HTML
<html>
<head>
    <style>
        body {
            background-color: #f0f8ff; /* light blue background */
            color: #333333; /* dark gray text */
            font-family: Arial, sans-serif; /* Set the font */
            margin: 0;
            padding: 20px;
        }
        .message {
            border: 2px solid #007bff; /* blue border */
            padding: 20px;
            border-radius: 5px; /* rounded corners */
            box-shadow: 0 4px 8px rgba(0,0,0,0.1); /* subtle shadow */
            max-width: 600px;
            margin: 40px auto; /* centering */
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="message">
        <p>{$message}</p>
    </div>
</body>
</html>
HTML;

        return new Response($htmlContent, Response::HTTP_OK, ['content-type' => 'text/html']);
    }

}
